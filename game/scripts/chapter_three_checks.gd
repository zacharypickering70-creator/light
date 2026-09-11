extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(value: bool, description: String) -> void:
	if not value: failures.append(description)
func shot(g: Node, boss: Dictionary, skill: String, vary: bool) -> void:
	g.last_cast=skill
	g.varied_cast=vary
	boss["count"]=2
	g._telegraph(boss)
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	g.set_process(false)
	g.test_mode=true
	g.music_player.stop()
	g._start_run()
	g._on_action("begin")
	g._show_learning(0)
	g._learn_skill("fire")
	g._on_action("resume")
	g._start_expedition()
	g.hp=87
	g.level=14
	g.xp=71
	g.wave_number=20
	g._finish_run(true)
	g._advance_stage()
	g._finish_run(true)
	g._advance_stage()
	check(g.chapter==3 and g.stage_depth==3 and g.world.landmarks[1]["name"]=="孟婆茶棚","third chapter route and landmarks")
	check(g.hp==87 and g.level==14 and g.xp==71 and g.wave_number==20,"chapter three carries run stats and wave count")
	check(g.world.worshippers.is_empty(),"no shrine worshippers in river map")
	var souls: Array=[]
	for pickup in g.pickups:
		if pickup["kind"]=="memory": souls.append(pickup)
	check(souls.size()==2,"two memory encounters")
	var points: int=g.study_points
	for i in range(souls.size()):
		g.player.position=souls[i]["pos"]
		g._interact()
		check(g.state=="memory_choice","soul opens choice")
		g._on_action("memory_keep" if i==0 else "memory_release")
		g._on_action("memory_keep")
		g._on_action("begin")
	check(g.remembered==1 and g.released_memories==1 and g.study_points==points+2,"both choices reward once")
	for pickup in g.pickups:
		if pickup["kind"]=="story":
			g.player.position=pickup["pos"]
			g._interact()
			check(g.ui._modal_description.text==g.ChapterThree.FRAGMENTS[pickup["id"]],"third chapter fragment text")
			g._on_action("begin")
	g.player.position=g.world.landmarks[6]["pos"]
	var boss: Dictionary=g._spawn_enemy("boss",g.player.position+Vector3(0,0,5))
	for mesh in boss["node"].get_node("Body").find_children("*","MeshInstance3D",true,false):
		if mesh.material_override is ShaderMaterial and mesh.material_override.shader==g.world.INK_SHADER:
			var ink: Color=mesh.material_override.get_shader_parameter("ink_color")
			check(not (ink.r>ink.g*1.3 and ink.r>0.3),"judge ink palette replaces red cloak")
	g._update_hud()
	var place_labels: Array=g.world.find_children("LandmarkTitle","Label3D",true,false)
	for label in place_labels:
		if label.text=="判影台": check(not label.visible,"boss place label yields to HUD")
	shot(g,boss,"frost",true)
	check(boss["attack"]=="mirror" and boss["echo_skill"]=="frost" and boss["timer"]>=1,"copied skill has clear telegraph")
	g.last_cast="fire"
	g.immunity=0
	g._resolve_enemy_attack(boss)
	check(g.rooted_left==0.8 and boss["timer"]==2.0,"copied control snapshot and varied recovery")
	g.dash_cd=0
	g._dash(Vector3.RIGHT)
	check(g.rooted_left==0,"copied root can be cleansed")
	g.dash_left=0
	g.immunity=0
	shot(g,boss,"fire",false)
	g.player.position+=Vector3(10,0,0)
	var hp_before: float=g.hp
	g._resolve_enemy_attack(boss)
	check(g.hp==hp_before and boss["timer"]==1.1,"leaving copied target avoids damage")
	boss["hp"]=boss["max_hp"]*0.5
	shot(g,boss,"barrier",false)
	g.player.position+=Vector3(10,0,0)
	var before: float=boss["hp"]
	g._resolve_enemy_attack(boss)
	check(boss["hp"]>before,"utility copy restores boss")
	for c in [1,2,3]:
		g.chapter=c
		g._begin_last_words(true)
		check(g.state=="last_words" and g.ui._modal.visible,"death dialogue starts")
		g._on_action("words_next")
		check(g.last_words_index==0,"first tap reveals text")
		g._on_action("words_next")
		check(g.last_words_index==1,"second tap advances speaker")
		g._on_action("words_skip")
		check(g.state=="transition" and g.ui._modal_description.visible_characters==-1,"dialogue skip restores full text and choice")
	g.chapter=3
	if DisplayServer.get_name()!="headless":
		g.player.position=g.world.landmarks[6]["pos"]+Vector3(0,0,7)
		g.camera.position=g.player.position+Vector3(0,22,18)
		g.camera.look_at(g.player.position)
		g.state="playing"
		g.ui.hide_modal()
		g.ui.set_combat_visible(true)
		g._update_hud()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/忘川旧市预览.png")
		g._begin_last_words(true)
		g._next_last_words()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/首领临终对话预览.png")
		g._on_action("words_skip")
	# Test the production dialogue-to-book transition, including all final lines.
	g.test_mode=false
	g._begin_last_words(true)
	for i in range(g.ChapterThree.last_words(3).size()):
		g._next_last_words()
		g._next_last_words()
	check(g.state=="chronicle","last line enters closing book")
	var book=g.get_child(g.get_child_count()-1)
	book.close()
	check(g.state=="transition","closing book offers continue and home")
	g.test_mode=true
	g._advance_stage()
	check(g.stage_depth==4 and g.chapter==4 and g._chapter_name()=="华山照影","fourth chapter follows third")
	g._finish_run(true)
	g._cash_out()
	check(not g.journey_started and g.level==1,"cashout still returns home")
	if failures.is_empty(): print("CHAPTER09_PASS: route, continuity, two choices, fragments, mirrored skills, evasion, death dialogue, book, cashout")
	else: print("CHAPTER09_FAIL: ",failures)
	quit(0 if failures.is_empty() else 1)
