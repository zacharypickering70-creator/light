extends SceneTree
var failures: Array[String] = []
func _initialize(): call_deferred("run")
func run():
	var world = load("res://scripts/open_world.gd").new()
	root.add_child(world)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 25
	camera.current = true
	var before_total: int = 0
	var after_total: int = 0
	for chapter in range(0,7):
		world.chapter = maxi(1,chapter)
		world.build_map(17017,chapter==0)
		await process_frame
		if "--screenshots" in OS.get_cmdline_user_args():
			var target: Vector3 = Vector3.ZERO if chapter==0 else world.landmarks[6]["pos"]
			camera.position = target + Vector3(0,22,17)
			camera.look_at(target)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/scene17-" + str(chapter) + ".png")
		var dressing = world.find_child("GroundDressing",true,false)
		if dressing == null: failures.append("missing dressing " + str(chapter))
		for node in world.find_children("*","Node3D",true,false):
			if node.has_meta("unbatched_parts"):
				before_total += int(node.get_meta("unbatched_parts"))
				after_total += int(node.get_meta("batched_parts"))
				if node.get_meta("batched_parts") > node.get_meta("unbatched_parts"): failures.append("batch inflation")
		for mesh in world.find_children("*","MeshInstance3D",true,false):
			if not mesh.get_aabb().is_finite(): failures.append("invalid bounds")
		if world.constrain_position(Vector3.ZERO).distance_to(Vector3.ZERO)>0.01: failures.append("blocked origin")
	if after_total >= before_total / 2: failures.append("static batching saving too small")
	print("SCENE17_BATCHES ", before_total," -> ",after_total," across home and six chapters")
	if failures.is_empty(): print("SCENE17_PASS")
	else: print("SCENE17_FAIL ", failures)
	quit(0 if failures.is_empty() else 1)
