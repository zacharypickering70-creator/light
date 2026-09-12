extends SceneTree

var failures: Array[String] = []
func _initialize(): call_deferred("run")
func check(value: bool, message: String):
	if not value: failures.append(message)

func run():
	var g = load("res://main.tscn").instantiate()
	root.add_child(g)
	g.set_process(false)
	g.test_mode = true
	g.music_player.stop()
	g._start_run()
	g._on_action("begin")
	check(g.pickups.filter(func(p): return p["kind"] == "scroll").is_empty(), "safe home has no field loot")
	g._show_learning(0)
	g._learn_skill("fire")
	g._on_action("resume")
	g._depart()
	var scrolls: Array = g.pickups.filter(func(p): return p["kind"] == "scroll")
	check(scrolls.size() == 3, "three scattered scrolls")
	check(g.pickups.filter(func(p): return p["kind"] == "supply").size() == 2, "two supply chests")
	check(g.pickups.filter(func(p): return p["kind"] == "chest").size() == 3, "three boon chests")
	var p: Dictionary = scrolls[0]
	p["skill"] = "frost"
	g.player.position = p["pos"]
	g._interact()
	check(g.state == "found_skill" and not p["used"], "opening does not consume scroll")
	g._on_action("scroll_leave")
	check(not p["used"] and g.state == "playing", "leave keeps scroll")
	g._interact()
	g._on_action("scroll_slot_1")
	check(g.state == "found_skill" and not p["used"], "locked slot cannot be filled")
	g.skill_cds[0] = 4.0
	g._on_action("scroll_slot_0")
	check(g.learned_skills == ["frost"] and g.study_points == 0 and p["used"], "free replacement consumes scroll once")
	check(g.skill_cds[0] == 4.0, "replacement preserves cooldown")
	p = scrolls[1]
	p["skill"] = "frost"
	g.player.position = p["pos"]
	g._interact()
	g._on_action("scroll_upgrade")
	check(g.skill_ranks["frost"] == 2, "duplicate scroll upgrades matching skill")
	g.level = 5
	p = scrolls[2]
	p["skill"] = "thunder"
	g.player.position = p["pos"]
	g._interact()
	g._on_action("scroll_slot_1")
	check(g.learned_skills == ["frost", "thunder"], "open slot learns scroll")
	var supply: Dictionary = g.pickups.filter(func(item): return item["kind"] == "supply")[0]
	g.hp = 20
	g.energy = 0
	g.player.position = supply["pos"]
	g._interact()
	check(g.hp > 20 and g.energy == 40 and supply["used"], "supply restores health and energy")
	g._hurt_player(20, "ranger_projectile")
	check(g.damage_sources.has("1:ranger_projectile"), "source recorded")
	g._hurt_player(20, "grunt_melee")
	check(not g.damage_sources.has("1:grunt_melee"), "immunity does not record damage")
	g.state = "transition"
	g._advance_stage()
	check(g.pickups.filter(func(item): return item["kind"] == "scroll").size() == 3, "next chapter replenishes exploration")
	check(g.learned_skills == ["frost", "thunder"] and g.damage_sources.has("1:ranger_projectile"), "growth and telemetry persist across chapters")
	if DisplayServer.get_name() != "headless":
		p = g.pickups.filter(func(item): return item["kind"] == "scroll")[0]
		g.player.position = p["pos"] + Vector3(0,0,2)
		g.camera.position = g.player.position + Vector3(0,22,18)
		g.camera.look_at(g.player.position)
		g._update_hud()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/遗卷探索预览.png")
		g._interact()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/遗卷学习预览.png")
	g._enter_home()
	check(g.learned_skills.is_empty() and g.found_scroll.is_empty() and g.damage_sources.is_empty(), "home clears temporary discoveries and telemetry")
	print("EXPLORATION_PASS" if failures.is_empty() else "EXPLORATION_FAIL " + str(failures))
	quit(0 if failures.is_empty() else 1)
