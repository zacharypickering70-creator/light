extends SceneTree

var failures: Array[String] = []

func _initialize(): call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func run():
	var world = load("res://scripts/open_world.gd").new()
	root.add_child(world)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 25
	camera.current = true
	for chapter in range(1, 7):
		world.chapter = chapter
		world.build_map(190019)
		await process_frame
		var surfaces: int = 0
		var vertices: int = 0
		var parts: int = 0
		var details: Array[Node] = world.find_children("ChapterDetails", "Node3D", true, false)
		check(details.size() == (0 if chapter == 1 else 7), "chapter detail count " + str(chapter))
		for detail in details:
			check(detail.get_meta("theme") == world.CHAPTER_ART.THEMES[chapter - 1], "chapter theme")
			parts += int(detail.get_meta("unbatched_parts"))
			for mesh in detail.find_children("*", "MeshInstance3D", true, false):
				surfaces += mesh.mesh.get_surface_count()
				for surface in range(mesh.mesh.get_surface_count()):
					vertices += mesh.mesh.surface_get_array_len(surface)
				check(mesh.get_aabb().is_finite(), "finite mesh bounds")
		check(surfaces <= 100, "chapter decor draw budget " + str(chapter))
		check(vertices <= 80000, "chapter decor vertex budget " + str(chapter))
		check(world.constrain_position(Vector3.ZERO).distance_to(Vector3.ZERO) < 0.01, "open start")
		for landmark in world.landmarks:
			check(world.constrain_position(landmark.pos).distance_to(landmark.pos) < 0.01, "open landmark center")
		var state_before: int = world._rng.state
		var obstacles_before: int = world.obstacles.size()
		var extra := Node3D.new()
		world.add_child(extra)
		var saved_room: Node3D = world._room
		world._room = extra
		world.CHAPTER_ART.dress(world, 2)
		world._room = saved_room
		check(world._rng.state == state_before, "cosmetic random isolation")
		check(world.obstacles.size() == obstacles_before, "cosmetic collision isolation")
		extra.free()
		print("CHAPTER_ART_BUDGET chapter=", chapter, " parts=", parts, " surfaces=", surfaces, " vertices=", vertices)
		if "--screenshots" in OS.get_cmdline_user_args():
			for id in ([3, 6] if chapter == 1 else [2, 6]):
				var target: Vector3 = world.landmarks[id].pos
				camera.position = target + Vector3(0, 22, 17)
				camera.look_at(target)
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://docs/地图精修19-第%d章-地标%d.png" % [chapter, id])
	if failures.is_empty(): print("CHAPTER_ART_PASS")
	else: print("CHAPTER_ART_FAIL ", failures)
	quit(0 if failures.is_empty() else 1)
