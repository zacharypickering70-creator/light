extends SceneTree
func _initialize(): call_deferred("run")
func capture(file: String):
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/"+file+".png")
func run():
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	g.set_process(false)
	g.test_mode=true
	g.music_player.stop()
	g._start_run()
	g.state="playing"
	g.rng.seed=18018
	g._start_expedition()
	g.state="playing"
	g.ui.hide_modal()
	for id in [3,4,6]:
		var center: Vector3=g.world.landmarks[id]["pos"]
		g.player.position=center
		g.camera.position=center+Vector3(0,22,18)
		g.camera.look_at(center)
		g._update_hud()
		await capture("渡口18-区域"+str(id))
	g.player.position=g.world.landmarks[0]["pos"]
	g.camera.position=g.player.position+Vector3(0,22,18)
	g.camera.look_at(g.player.position)
	g._spawn_enemy("brute",g.player.position+Vector3(0,0,-2))
	g.progress["equipped"]["blade"]="heavy_cleaver"
	g._refresh_gear_visual()
	g.combo=2
	g._attack()
	g._animate_player(0.016,Vector3.ZERO)
	g._update_hud()
	await capture("战斗18-重击")
	print("FERRY18_PREVIEW_PASS")
	quit()
