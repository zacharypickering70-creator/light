extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(value: bool, reason: String) -> void:
	if not value: failures.append(reason)
func prepare(g: Node, enemy: Dictionary, attack: int) -> void:
	g.state="playing"
	g.hp=300
	g.max_hp=300
	g.shield_hp=0
	g.immunity=0
	g.player.position=Vector3.ZERO
	enemy["node"].position=Vector3(0,0,5)
	enemy["count"]=attack-1 if attack>0 else 2
	g._telegraph(enemy)
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
	g.level=21
	g.xp=113
	g.wave_number=50
	g.hp=89
	g.energy=63
	for i in range(3):
		g._finish_run(true)
		g._advance_stage()
	check(g.stage_depth==4 and g.chapter==4 and g._chapter_name()=="华山照影","fourth chapter route")
	check(g.level==21 and g.xp==113 and g.wave_number==50 and g.hp==89 and g.energy==63,"continuous state retained")
	check(g.world.landmarks.size()==7 and g.world.landmarks[6]["name"]=="天眼台","seven mountain landmarks")
	var points: int=g.study_points
	for pickup in g.pickups:
		if pickup["kind"]=="anchor":
			g.player.position=pickup["pos"]
			g._interact()
			g._on_action("begin")
			g._interact()
			g._on_action("begin")
	check(g.anchored_lights==2 and g.study_points==points+2,"two anchors reward once")
	for pickup in g.pickups:
		if pickup["kind"]=="story":
			g.player.position=pickup["pos"]
			g._interact()
			check(g.ui._modal_description.text==g.ChapterFour.FRAGMENTS[pickup["id"]],"mountain story fragments")
			g._on_action("begin")
	var boss: Dictionary=g._spawn_enemy("boss",Vector3(0,0,5))
	for i in range(8):
		g.player.position=Vector3(cos(i*TAU/8),0,sin(i*TAU/8))*53.9
		boss["count"]=2
		g._telegraph(boss)
		for a in range(3):
			for b in range(a): check(boss["sky_points"][a].distance_to(boss["sky_points"][b])>5.0,"edge markers stay separated")
	prepare(g,boss,0)
	check(boss["attack"]=="sky_eye" and boss["sky_marks"].size()==3,"three initial illusion markers")
	g.ChapterFour.tick_reveal(g,boss)
	check(not boss["sky_revealed"],"illusions reveal after initial delay")
	boss["timer"]=boss["sky_duration"]-0.56
	g.ChapterFour.tick_reveal(g,boss)
	check(boss["sky_revealed"] and boss["sky_marks"].size()==6 and boss["timer"]>=0.9,"real and false glyphs with reaction time")
	var false_index: int=(boss["sky_true"]+1)%3
	g.player.position=boss["sky_points"][false_index]
	g._resolve_enemy_attack(boss)
	check(g.hp==300 and boss["sky_marks"].is_empty(),"false location never damages and markers clear")
	prepare(g,boss,0)
	g.player.position=boss["sky_points"][boss["sky_true"]]
	g._resolve_enemy_attack(boss)
	check(g.hp<300 and boss["timer"]==2.0,"real location damages and opens recovery")
	prepare(g,boss,1)
	g.player.position=Vector3(10,0,0)
	g._resolve_enemy_attack(boss)
	check(g.hp==300 and boss["node"].position.distance_to(Vector3.ZERO)<0.01,"spear commits to old target")
	for distance in [0.0,4.0,9.0]:
		prepare(g,boss,2)
		g.player.position=boss["target"]+Vector3(distance,0,0)
		g._resolve_enemy_attack(boss)
		check((g.hp<300)==(distance==4.0),"annulus inner and outer safe zones")
	prepare(g,boss,0)
	var old_marks: Array=boss["sky_marks"].duplicate()
	g._damage_enemy(boss,100000,g.player.position)
	await process_frame
	for mark in old_marks: check(not is_instance_valid(mark),"boss defeat clears illusion markers")
	g._begin_last_words(true)
	check(g.ui._modal_title.text=="二郎神" and g.ui._modal_eyebrow.text.contains("真君收刀"),"Erlang dialogue is a yielding conversation")
	g._on_action("words_next")
	g._on_action("words_next")
	check(g.ui._modal_title.text=="提灯人","speaker advances")
	g._on_action("words_skip")
	check(g.state=="transition","dialogue skip preserves chapter choice")
	g.test_mode=false
	g._play_chapter_book(true)
	check(g.state=="chronicle","mountain closing book")
	var book=g.get_child(g.get_child_count()-1)
	check(book.pages.size()==3 and book.pages[1]["text"].contains("2 处归灯"),"closing acknowledges anchors")
	book.close()
	g.test_mode=true
	if DisplayServer.get_name()!="headless":
		g.ui.hide_modal()
		g.state="playing"
		g.player.position=g.world.landmarks[6]["pos"]+Vector3(0,0,8)
		g.camera.position=g.player.position+Vector3(0,22,18)
		g.camera.look_at(g.player.position)
		boss=g._spawn_enemy("boss",g.player.position+Vector3(0,0,-5))
		boss["count"]=2
		g._telegraph(boss)
		boss["timer"]=1.0
		g.ChapterFour.tick_reveal(g,boss)
		g.ui.set_combat_visible(true)
		g._update_hud()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/华山照影预览.png")
		g._begin_last_words(true)
		g._next_last_words()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/真君收刀预览.png")
		g._on_action("words_skip")
	g._advance_stage()
	check(g.stage_depth==5 and g.chapter==5 and g._chapter_name()=="莲心台","fifth chapter route")
	g._finish_run(true)
	g._on_action("ending_keep")
	g._cash_out()
	check(not g.journey_started and g.level==1,"home settlement remains valid")
	if failures.is_empty(): print("CHAPTER10_PASS: continuity, anchors, fragments, reveal, real/false damage, spear, annulus, marker cleanup, dialogue, book, home")
	else: print("CHAPTER10_FAIL: ",failures)
	quit(0 if failures.is_empty() else 1)
