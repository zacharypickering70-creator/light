extends SceneTree

var failures: Array[String] = []
var screenshots: bool = false
func _initialize(): call_deferred("run")
func check(condition: bool, message: String):
	if not condition: failures.append(message)

func check_controls(ui: Node, label: String):
	var buttons: Array = []
	var bounds := Rect2(ui._root.global_position, ui._root.size)
	for id in ui._combat_buttons:
		var button: Button = ui._combat_buttons[id]
		if not button.is_visible_in_tree(): continue
		buttons.append(button)
		check(bounds.encloses(button.get_global_rect()), label + " bounds " + id)
		var center: Vector2 = button.get_global_transform_with_canvas() * (button.size * 0.5)
		check(ui._combat_action_at(center) == id, label + " touch target " + id)
	for i in range(buttons.size()):
		for j in range(i + 1, buttons.size()):
			check(not buttons[i].get_global_rect().intersects(buttons[j].get_global_rect()), label + " overlapping buttons")
	check(ui._left_stack.size.y < 280, label + " left HUD remains compact")
	check(not ui._left_stack.get_global_rect().intersects(ui._joystick.get_global_rect()), label + " joystick clear")
	check(not ui._experience_hint.get_global_rect().intersects(ui._combat_buttons["interact"].get_global_rect()), label + " experience hint clears interaction")
	check(not ui._map_view.get_global_rect().intersects(ui._combat_buttons["pause"].get_global_rect()), label + " map clears pause")
	if ui._boss_box.visible:
		check(not ui._boss_box.get_global_rect().intersects(ui._left_stack.get_global_rect()), label + " boss clears player stats")
		check(not ui._boss_box.get_global_rect().intersects(ui._map_view.get_global_rect()), label + " boss clears map")

func capture(name: String):
	if screenshots:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/" + name + ".png")

func run():
	screenshots = DisplayServer.get_name() != "headless"
	var g = load("res://main.tscn").instantiate()
	root.add_child(g)
	g.set_process(false)
	g.test_mode = true
	g.music_player.stop()
	g._start_run()
	g._on_action("begin")
	g._update_hud()
	await process_frame
	await process_frame
	check_controls(g.ui, "home")
	await capture("布局16-家园")
	g._show_learning(0)
	g._learn_skill("fire")
	g._on_action("resume")
	g._depart()
	g.level = 5
	g.xp = 320
	g.xp_next = 380
	g.learned_skills.assign(["fire", "frost", "quake"])
	g.skill_ranks = {"fire":3, "frost":2, "quake":1}
	g.skill_cds.assign([0.0, 3.2, 0.0])
	g.dash_cd = 0.8
	g.ultimate_id = "tempest"
	g.ultimate_charge = 67
	g.wave_number = 20
	g.stage_seconds = 112
	g._spawn_boss()
	for enemy in g.enemies:
		if enemy["kind"] == "boss": enemy["node"].position = g.player.position + Vector3(0,0,-6)
	g.ui.hide_modal()
	for format in [["16-9",Vector2i(1280,720)], ["20-9",Vector2i(1600,720)], ["4-3",Vector2i(1280,960)], ["small",Vector2i(960,540)]]:
		root.size = format[1]
		await process_frame
		await process_frame
		g._update_hud()
		g.ui._combat_buttons["interact"].visible = true
		g.ui._combat_buttons["interact"].text = "参悟遗卷"
		g.ui.toast("拾得武学遗卷 · 靠近后参悟")
		await process_frame
		check_controls(g.ui, format[0])
		check(g.ui._ultimate_button.get_meta("caption").text == "九霄雷狱", "ultimate name remains visible")
		check(g.ui._dash_button.get_meta("caption").text == "踏影", "dash name remains visible")
		await capture("布局16-战斗-" + format[0])
		g._show_boons("level")
		await process_frame
		await process_frame
		check(g.ui._modal_grid.columns == 3, format[0] + " compare three boons")
		for card in g.ui._modal_grid.get_children():
			check(g.ui._modal_scroll.get_global_rect().encloses(card.get_global_rect()), format[0] + " boon card visible")
		await capture("布局16-升级-" + format[0])
		g.state = "playing"
		g.ui.hide_modal()
	root.size = Vector2i(1280,720)
	await process_frame
	g.ui._root.offset_left = 48
	g.ui._root.offset_right = -24
	g.ui._root.offset_top = 12
	g.ui._root.offset_bottom = -20
	await process_frame
	g._update_hud()
	await process_frame
	check_controls(g.ui, "safe insets")
	var attack: Button = g.ui._combat_buttons["attack"]
	var press := InputEventScreenTouch.new()
	press.index = 3
	press.position = attack.get_global_transform_with_canvas() * (attack.size * 0.5)
	press.pressed = true
	g.ui._input(press)
	check(g.ui.attack_held, "touch holds attack after layout")
	var skill: Button = g.ui._combat_buttons["skill_0"]
	var second_touch := InputEventScreenTouch.new()
	second_touch.index = 4
	second_touch.position = skill.get_global_transform_with_canvas() * (skill.size * 0.5)
	second_touch.pressed = true
	g.ui._input(second_touch)
	check(g.ui.attack_held and g.skill_cds[0] > 0, "second finger casts without releasing attack")
	second_touch.pressed = false
	g.ui._input(second_touch)
	check(g.ui.attack_held, "skill release preserves attack finger")
	var release := InputEventScreenTouch.new()
	release.index = 3
	release.position = press.position
	release.pressed = false
	g.ui._input(release)
	check(not g.ui.attack_held, "release clears attack")
	await capture("布局16-安全边距")
	g._show_learning(0)
	await process_frame
	await process_frame
	check(g.ui._modal_grid.columns == 2, "long learning menu keeps two columns")
	for card in g.ui._modal_grid.get_children():
		check(card.get_global_rect().end.x <= g.ui._modal_scroll.get_global_rect().end.x, "learning cards stay inside panel width")
	await capture("布局16-武学列表")
	print("UI_LAYOUT_PASS" if failures.is_empty() else "UI_LAYOUT_FAIL " + str(failures))
	quit(0 if failures.is_empty() else 1)
