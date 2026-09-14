extends SceneTree
const Tactics=preload("res://scripts/enemy_tactics.gd")
const Models=preload("res://scripts/model_library.gd")
func _initialize(): call_deferred("run")
func capture(name: String):
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/"+name+".png")
func run():
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	g.set_process(false)
	g.test_mode=true
	g.music_player.stop()
	g._start_run()
	g.state="playing"
	g.rng.seed=190019
	g._start_expedition()
	g.state="playing"
	g.ui.hide_modal()
	g.player.position=Vector3.ZERO
	g.camera.position=Vector3(0,22,18)
	g.camera.look_at(Vector3.ZERO)
	g.level=5
	g.learned_skills.assign(["fire","vortex","thunder"])
	g.skill_ranks={"fire":3,"vortex":2,"thunder":1}
	g.progress["equipped"]["blade"]="heavy_cleaver"
	g._refresh_gear_visual()
	var brute: Dictionary=g._spawn_enemy("brute",Vector3(0,0,-5.5))
	Tactics.begin_charge(g,brute)
	var ranger: Dictionary=g._spawn_enemy("ranger",Vector3(5.5,0,-3))
	g._telegraph(ranger)
	for i in range(4):
		g._spawn_enemy("grunt",Vector3(-5.0+i*2.8,0,3.5 if i%2 else -4.8))
	for enemy in g.enemies: Models.animate_enemy(enemy["node"],0.6,enemy["mode"],0.22)
	g._animate_player(0.1,Vector3.ZERO)
	g._update_hud()
	await capture("战术精修-混战预警")
	g._test_clear_enemies()
	g._clear_projectiles()
	for i in range(4):
		var enemy: Dictionary=g._spawn_enemy("brute",Vector3(-1.8+i*1.2,0,-2.3))
		enemy["hp"]=1000
		enemy["max_hp"]=1000
	g.combo=2
	g._attack()
	g._animate_player(0.08,Vector3.ZERO)
	g._update_hud()
	await capture("战术精修-重斧连段")
	print("COMBAT_READABILITY_PASS")
	quit()
