extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(value: bool, reason: String) -> void:
	if not value: failures.append(reason)
func prepare(g: Node, boss: Dictionary, fraction: float) -> void:
	g.state="playing"
	g.hp=300
	g.max_hp=300
	g.shield_hp=0
	g.immunity=0
	g.player.position=Vector3.ZERO
	boss["node"].position=Vector3(0,0,5)
	boss["hp"]=boss["max_hp"]*fraction
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
	g.level=27
	g.xp=173
	g.wave_number=67
	g.hp=91
	g.energy=69
	for i in range(4):
		g._finish_run(true)
		g._advance_stage()
	check(g.stage_depth==5 and g.chapter==5 and g._chapter_name()=="莲心台","route into finale")
	check(g.level==27 and g.xp==173 and g.wave_number==67 and g.hp==91 and g.energy==69,"continuity")
	check(g.world.landmarks.size()==7 and g.world.landmarks[6]["name"]=="莲心台","final landmarks")
	for pickup in g.pickups:
		if pickup["kind"]=="voice":
			g.player.position=pickup["pos"]
			g._interact()
			check(g.ui._modal_description.text==g.ChapterFive.VOICES[pickup["id"]][1],"voice content")
			g._on_action("begin")
			g._interact()
			g._on_action("begin")
	check(g.final_voices.size()==3,"three unique voices")
	for pickup in g.pickups:
		if pickup["kind"]=="story":
			g.player.position=pickup["pos"]
			g._interact()
			check(g.ui._modal_description.text==g.ChapterFive.FRAGMENTS[pickup["id"]],"final fragments")
			g._on_action("begin")
	var boss: Dictionary=g._spawn_enemy("boss",Vector3(0,0,5))
	prepare(g,boss,1.0)
	check(boss["attack"]=="ink_seals" and boss["lotus_points"].size()==3,"first phase seals")
	g._resolve_enemy_attack(boss)
	check(g.hp<300,"seal damage")
	prepare(g,boss,1.0)
	g.player.position=Vector3(0,0,4)
	g._resolve_enemy_attack(boss)
	check(g.hp==300,"seal escape")
	for i in range(8):
		prepare(g,boss,1.0)
		g.player.position=Vector3(cos(i*TAU/8),0,sin(i*TAU/8))*53.9
		g._telegraph(boss)
		for a in range(3):
			check(boss["lotus_points"][a].length()<54,"seals inside map")
			for b in range(a): check(boss["lotus_points"][a].distance_to(boss["lotus_points"][b])>5.0,"edge seals separate")
	for distance in [0.0,4.0,9.0]:
		prepare(g,boss,0.6)
		check(boss["lotus_phase"]==2 and boss["attack"]=="wish_echo","second phase")
		g.player.position=boss["target"]+Vector3(distance,0,0)
		g._resolve_enemy_attack(boss)
		check((g.hp<300)==(distance==4.0),"echo ring safe zones")
	prepare(g,boss,0.3)
	check(boss["lotus_marks"][0].mesh.size==Vector3(3.6,0.025,12),"stroke warning matches collision width and length")
	var old_scene=g.world.final_scene
	check(boss["lotus_phase"]==3 and is_instance_valid(old_scene),"courtyard phase")
	g._resolve_enemy_attack(boss)
	check(g.hp<300 and boss["timer"]==2.1,"stroke hit and recovery")
	prepare(g,boss,0.3)
	g.player.position=Vector3(4,0,0)
	g._resolve_enemy_attack(boss)
	check(g.hp==300,"stroke sidestep")
	prepare(g,boss,0.3)
	var marks: Array=boss["lotus_marks"].duplicate()
	g._damage_enemy(boss,10000000,g.player.position)
	await process_frame
	for mark in marks: check(not is_instance_valid(mark),"defeat clears markers")
	check(g.state=="ending_choice","defeat requires an ending")
	var reward: int=g.earned_incense
	g._finish_run(true)
	check(g.earned_incense==reward,"no duplicate victory reward")
	g._begin_last_words(true)
	check(g.ui._modal_title.text=="陆照川" and g.ui._modal_eyebrow.text.contains("灯前问答"),"master dialogue")
	g._on_action("words_skip")
	check(g.state=="ending_choice","skip cannot skip decision")
	g.final_voices.clear()
	g._on_action("ending_open")
	check(g.ending_choice.is_empty() and g.state=="ending_choice","leave door requires voices")
	for i in range(3):
		g._on_action("ending_listen")
		check(g.state=="ending_voice" and g.final_voices.size()==i+1,"missing voice catchup")
		g._on_action("ending_return")
	for choice in ["keep","break","open"]:
		g.ending_choice=""
		g._show_final_choice()
		g.test_mode=false
		g._on_action("ending_"+choice)
		check(g.ending_choice==choice and g.state=="chronicle","each ending opens book")
		var book=g.get_child(g.get_child_count()-1)
		check(book.pages[0]["title"]==g.ChapterFive.ENDINGS[choice][0],"correct ending prose")
		g._on_action("ending_keep")
		check(g.ending_choice==choice,"choice cannot be overwritten")
		book.close()
		check(g.state=="transition","ending reaches settlement choice")
		g.test_mode=true
	if DisplayServer.get_name()!="headless":
		g.ui.hide_modal()
		g.state="playing"
		boss=g._spawn_enemy("boss",Vector3(0,0,5))
		prepare(g,boss,0.3)
		g.camera.position=g.player.position+Vector3(0,22,18)
		g.camera.look_at(g.player.position)
		g.ui.set_combat_visible(true)
		g._update_hud()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/莲心台终战预览.png")
		g.final_voices.clear()
		g._show_final_choice()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/终章抉择预览.png")
		for i in range(3):
			g._on_action("ending_listen")
			g._on_action("ending_return")
		g.ending_choice=""
		g._on_action("ending_open")
	g._advance_stage()
	await process_frame
	check(g.stage_depth==6 and g.chapter==5 and g._chapter_name().contains("愿境深处"),"poststory endless realm")
	check(not is_instance_valid(old_scene),"old phase scene removed on transition")
	g._finish_run(true)
	check(g.state=="transition","later realms do not repeat ending choice")
	g._cash_out()
	check(not g.journey_started and g.level==1 and g.final_voices.is_empty() and g.ending_choice.is_empty(),"home resets journey")
	if failures.is_empty(): print("CHAPTER11_PASS: route, continuity, voices, fragments, three phases, evasion, edges, cleanup, dialogue, three endings, catchup, settlement")
	else: print("CHAPTER11_FAIL: ",failures)
	quit(0 if failures.is_empty() else 1)
