extends SceneTree
var failures: Array[String] = []
func _initialize(): call_deferred("run")
func check(condition: bool, message: String):
	if not condition: failures.append(message)
func run():
	var g = load("res://main.tscn").instantiate()
	root.add_child(g)
	g.set_process(false)
	g.test_mode = true
	g.music_player.stop()
	g._start_run()
	g._on_action("begin")
	g._show_learning(0)
	g._learn_skill("fire")
	g._on_action("resume")
	g._depart()
	g.chapter = 2
	g.player.position = Vector3.ZERO
	var enemy: Dictionary = g._spawn_enemy("ranger", Vector3(0,0,8))
	for shot in range(1, 4):
		g._telegraph(enemy)
		check(is_equal_approx(enemy["timer"], 0.9), "second chapter gives 0.9 seconds warning")
		check(enemy["tell"].get_child_count() == (3 if shot == 3 else 1), "warning matches projectile count")
		var before: int = g.projectiles.size()
		g._resolve_enemy_attack(enemy)
		check(g.projectiles.size() - before == (3 if shot == 3 else 1), "two single shots then a fan")
		check(g.projectiles.back()["source"] == "ranger_projectile", "projectiles retain owner")
	g.state = "playing"
	g.immunity = 0
	g.shield_hp = 10
	g.hp = 50
	g.progress["equipped"]["robe"] = "pilgrim_robe"
	g.passives.clear()
	g._hurt_player(30, "ranger_projectile")
	var record: Dictionary = g.damage_sources["1:ranger_projectile"]
	check(record["absorbed"] == 10 and record["health_damage"] == 20, "separate shield absorption and health loss")
	if DisplayServer.get_name() != "headless":
		enemy["count"] = 2
		g._telegraph(enemy)
		g.camera.position = Vector3(0,22,18)
		g.camera.look_at(Vector3.ZERO)
		g._update_hud()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/远程预警预览.png")
	print("RANGER_PASS" if failures.is_empty() else "RANGER_FAIL " + str(failures))
	quit(0 if failures.is_empty() else 1)
