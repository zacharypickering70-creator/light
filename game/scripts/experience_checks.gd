extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func run() -> void:
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
	g.xp = 31
	g._update_hud()
	check(not g.ui._experience_hint.visible, "below 80 percent stays quiet")
	g.xp = 32
	g._update_hud()
	check(g.ui._experience_hint.visible and g.ui._experience_hint.text.contains("8 经验"), "80 percent displays remaining experience")
	check(g.ui._experience_text.text.contains("32 / 40"), "numeric progress")
	check(g.ui._experience.custom_minimum_size.y >= 10, "experience bar is legible")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/经验提示预览.png")
	var enemy: Dictionary = g._spawn_enemy("grunt", Vector3(2, 0, 2))
	g._kill_enemy(enemy)
	g._update_hud()
	check(g.level == 2 and g.xp == 0 and g.xp_next == 85, "kill reaches next level with increasing requirement")
	check(not g.ui._experience_hint.visible, "near-level hint clears after upgrade")
	g._show_boons("level")
	check(g.ui._modal_title.text == "修为提升 · 2 级", "upgrade states what happened")
	check(g.ui._modal_description.text.contains("学习点"), "upgrade explains next action")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/升级引导预览.png")
	g.state = "playing"
	g.xp = 80
	enemy = g._spawn_enemy("brute", Vector3(3, 0, 2))
	g._kill_enemy(enemy)
	check(g.level == 3 and g.xp == 13 and g.xp_next == 160, "overflow carries into next level")
	for level in range(2, 101):
		check(g._xp_requirement(level) > g._xp_requirement(level - 1), "requirements increase through level 100")
	g._enter_home()
	g._update_hud()
	check(not g.ui._experience_hint.visible, "home has no upgrade warning")
	print("EXPERIENCE_PASS" if failures.is_empty() else "EXPERIENCE_FAIL " + str(failures))
	quit(0 if failures.is_empty() else 1)
