extends Node3D
## Original procedural model and architecture library.

var _materials: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _room: Node3D
var _ember_nodes: Array[Node3D] = []
var _time: float = 0.0

const STONE := Color("51595a")
const DARK_STONE := Color("263a3c")
const WOOD := Color("3e2927")
const ROOF := Color("233c3d")
const GOLD := Color("b69b60")
const VERMILION := Color("86332c")


func create_actor(kind: String, chapter_id: int=1) -> Node3D:
	return preload("res://scripts/model_library.gd").actor(kind,chapter_id)


func _process(delta: float) -> void:
	_time += delta
	for i in range(_ember_nodes.size()):
		var ember: Node3D = _ember_nodes[i]
		if is_instance_valid(ember):
			ember.position.y = float(ember.get_meta("base_y")) + sin(_time * 0.72 + i * 1.7) * 0.20
			ember.rotation.y += delta * 0.3


func _gate(pos: Vector3, width: float, size_factor: float, accent: Color) -> void:
	var gate := Node3D.new()
	_room.add_child(gate)
	gate.position = pos
	gate.scale = Vector3.ONE * size_factor
	for side in [-1.0, 1.0]:
		var x: float = side * width * 0.39
		_box(gate, Vector3(x, 0.18, 0), Vector3(0.64, 0.36, 0.70), STONE)
		_cylinder(gate, Vector3(x, 1.67, 0), 0.20, 0.23, 2.66, WOOD, 10)
		_cylinder(gate, Vector3(x, 0.52, 0), 0.26, 0.29, 0.28, DARK_STONE, 8)
		_cylinder(gate, Vector3(x, 2.84, 0), 0.27, 0.24, 0.19, GOLD.darkened(0.2), 8)
		_beam(gate, Vector3(x, 2.37, 0), Vector3(x - side * 0.69, 3.00, 0), 0.105, WOOD)
		_lantern_small(gate, Vector3(x - side * 0.48, 2.06, -0.11), accent, 1.12)
	_box(gate, Vector3(0, 3.05, 0), Vector3(width, 0.23, 0.31), WOOD)
	_box(gate, Vector3(0, 2.61, 0.02), Vector3(width * 0.42, 0.54, 0.20), Color("273435"))
	_box(gate, Vector3(0, 2.89, -0.10), Vector3(width * 0.45, 0.045, 0.05), GOLD)
	_box(gate, Vector3(0, 2.35, -0.10), Vector3(width * 0.45, 0.045, 0.05), GOLD)
	for i in range(3):
		var x: float = (i - 1) * 0.32
		_box(gate, Vector3(x, 2.62, 0.14), Vector3(0.055, 0.27, 0.016), GOLD)
		_box(gate, Vector3(x, 2.65, 0.15), Vector3(0.20, 0.045, 0.017), GOLD)
		_box(gate, Vector3(x + 0.04, 2.53, 0.15), Vector3(0.16, 0.04, 0.017), GOLD)
	_roof(gate, Vector3(0, 3.17, 0), width * 0.64, 1.28, ROOF)
	_roof(gate, Vector3(0, 3.88, 0), width * 0.47, 0.88, ROOF.darkened(0.04))


func _roof(parent: Node3D, pos: Vector3, half_width: float, half_depth: float, color: Color) -> void:
	var roof := Node3D.new()
	parent.add_child(roof)
	roof.position = pos
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx: int = 16
	var nz: int = 12
	for ix in range(nx):
		for iz in range(nz):
			var u0: float = float(ix) / nx * 2.0 - 1.0
			var u1: float = float(ix + 1) / nx * 2.0 - 1.0
			var v0: float = float(iz) / nz * 2.0 - 1.0
			var v1: float = float(iz + 1) / nz * 2.0 - 1.0
			var p0: Vector3 = _roof_point(u0, v0, half_width, half_depth)
			var p1: Vector3 = _roof_point(u1, v0, half_width, half_depth)
			var p2: Vector3 = _roof_point(u1, v1, half_width, half_depth)
			var p3: Vector3 = _roof_point(u0, v1, half_width, half_depth)
			for p in [p0, p1, p2, p0, p2, p3]:
				surface.add_vertex(p)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = _material(color, 0.0, true)
	roof.add_child(mesh)
	# Raised ribs, dark eaves, gold ridge, and turned-up corners give the roof its silhouette.
	for i in range(13):
		var u: float = float(i) / 12.0 * 2.0 - 1.0
		for side in [-1.0, 1.0]:
			for j in range(4):
				var a: Vector3 = _roof_point(u, side * float(j) / 4.0, half_width, half_depth)
				var b: Vector3 = _roof_point(u, side * float(j + 1) / 4.0, half_width, half_depth)
				_beam(roof, a + Vector3.UP * 0.025, b + Vector3.UP * 0.025, 0.027, color.lightened(0.075))
	for side in [-1.0, 1.0]:
		for i in range(8):
			var u0: float = float(i) / 8.0 * 2.0 - 1.0
			var u1: float = float(i + 1) / 8.0 * 2.0 - 1.0
			_beam(roof, _roof_point(u0, side, half_width, half_depth), _roof_point(u1, side, half_width, half_depth), 0.070, WOOD)
		var tip: Vector3 = _roof_point(side, 0, half_width, half_depth)
		_beam(roof, tip, tip + Vector3(side * 0.25, 0.35, 0), 0.055, GOLD.darkened(0.12))
		_sphere(roof, tip + Vector3(side * 0.25, 0.35, 0), 0.086, GOLD, 8)
	_beam(roof, Vector3(-half_width, 0.91, 0), Vector3(half_width, 0.91, 0), 0.065, GOLD.darkened(0.24))


func _roof_point(u: float, v: float, half_width: float, half_depth: float) -> Vector3:
	var y: float = 0.83 * pow(1.0 - absf(v), 1.65) + 0.31 * pow(absf(v), 6.0) + 0.31 * pow(absf(u), 5.0)
	return Vector3(u * half_width, y, v * half_depth)


func _pavilion(pos: Vector3, side: float) -> void:
	var temple := Node3D.new()
	_room.add_child(temple)
	temple.position = pos
	_box(temple, Vector3(0, 0.22, 0), Vector3(5.0, 0.48, 4.4), DARK_STONE)
	_box(temple, Vector3(0, 0.48, 0), Vector3(5.3, 0.17, 4.7), STONE)
	for x in [-1.9, 1.9]:
		for z in [-1.6, 1.6]:
			_cylinder(temple, Vector3(x, 1.93, z), 0.15, 0.18, 2.75, WOOD, 10)
	_box(temple, Vector3(side * 1.96, 1.88, 0), Vector3(0.16, 2.45, 3.3), Color("37423d"))
	for i in range(9):
		_box(temple, Vector3(side * 1.84, 1.9, -1.43 + i * 0.36), Vector3(0.075, 2.38, 0.066), WOOD)
	_roof(temple, Vector3(0, 3.18, 0), 3.1, 2.65, ROOF)
	_roof(temple, Vector3(0, 4.09, 0), 2.0, 1.7, ROOF.darkened(0.07))


func _lantern(pos: Vector3, size_factor: float, color: Color, tall: bool) -> void:
	var lamp := Node3D.new()
	_room.add_child(lamp)
	lamp.position = pos
	lamp.scale = Vector3.ONE * size_factor
	_box(lamp, Vector3(0, 0.13, 0), Vector3(0.84, 0.26, 0.84), DARK_STONE)
	_cylinder(lamp, Vector3(0, 0.33, 0), 0.40, 0.48, 0.16, STONE, 6)
	_cylinder(lamp, Vector3(0, 0.93, 0), 0.15, 0.22, 1.1, STONE, 8)
	_cylinder(lamp, Vector3(0, 1.43, 0), 0.34, 0.26, 0.15, STONE, 6)
	_box(lamp, Vector3(0, 1.75, 0), Vector3(0.39, 0.52, 0.39), color, 1.6)
	for x in [-0.26, 0.26]:
		for z in [-0.26, 0.26]:
			_box(lamp, Vector3(x, 1.75, z), Vector3(0.075, 0.61, 0.075), DARK_STONE)
	_cylinder(lamp, Vector3(0, 2.07, 0), 0.19, 0.57, 0.24, STONE, 6)
	_cylinder(lamp, Vector3(0, 2.25, 0), 0.055, 0.19, 0.17, DARK_STONE, 6)
	if tall:
		_sphere(lamp, Vector3(0, 2.42, 0), 0.12, GOLD, 8)


func _lantern_small(parent: Node3D, pos: Vector3, color: Color, size_factor: float = 1.0) -> void:
	var lantern := Node3D.new()
	parent.add_child(lantern)
	lantern.position = pos
	lantern.scale = Vector3.ONE * size_factor
	_beam(lantern, Vector3(0, 0.11, 0), Vector3(0, 0.34, 0), 0.018, GOLD)
	_cylinder(lantern, Vector3.ZERO, 0.145, 0.115, 0.25, color, 8, 1.7)
	_cylinder(lantern, Vector3(0, 0.145, 0), 0.065, 0.17, 0.08, GOLD, 8)
	_cylinder(lantern, Vector3(0, -0.15, 0), 0.14, 0.13, 0.06, GOLD, 8)
	for n in range(8):
		var a: float = TAU * float(n) / 8.0
		_box(lantern, Vector3(sin(a) * 0.14, 0, cos(a) * 0.14), Vector3(0.019, 0.25, 0.019), WOOD)
	_beam(lantern, Vector3(0, -0.16, 0), Vector3(0, -0.33, 0), 0.02, VERMILION)


func _tree(pos: Vector3, side: float, size_factor: float) -> void:
	var tree := Node3D.new()
	_room.add_child(tree)
	tree.position = pos
	tree.scale = Vector3.ONE * size_factor
	var bark := Color("303b37")
	_beam(tree, Vector3.ZERO, Vector3(side * 0.25, 1.7, 0.1), 0.26, bark)
	_beam(tree, Vector3(side * 0.25, 1.7, 0.1), Vector3(side * 0.15, 3.25, -0.1), 0.19, bark)
	_beam(tree, Vector3(side * 0.15, 3.25, -0.1), Vector3(side * 0.70, 4.5, -0.4), 0.11, bark)
	_beam(tree, Vector3(side * 0.70, 4.5, -0.4), Vector3(side * 1.8, 5.02, -0.1), 0.055, bark)
	for i in range(5):
		var p := Vector3(side * 0.20, 1.75 + float(i) * 0.42, 0)
		var direction: float = -1.0 if i % 2 == 0 else 1.0
		var end := p + Vector3(side * direction * (1.2 + i * 0.10), 0.6 + i * 0.12, _rng.randf_range(-0.6, 0.6))
		_beam(tree, p, end, 0.10 - i * 0.011, bark)
		var tip: Vector3 = end + Vector3(side * direction * 0.55, 0.78, -0.35)
		_beam(tree, end, tip, 0.042, bark)
		_beam(tree, end.lerp(tip, 0.35), end + Vector3(side * direction * 0.70, 0.25, 0.37), 0.025, bark)
	for n in range(5):
		var a: float = n * TAU / 5.0
		_beam(tree, Vector3(0, 0.3, 0), Vector3(sin(a) * 0.95, 0.04, cos(a) * 0.90), 0.14, bark)


func _banner(pos: Vector3, side: float, color: Color) -> void:
	var flag := Node3D.new()
	_room.add_child(flag)
	flag.position = pos
	_box(flag, Vector3(0, 0.13, 0), Vector3(0.7, 0.26, 0.7), DARK_STONE)
	_beam(flag, Vector3.ZERO, Vector3(0, 4.15, 0), 0.055, WOOD)
	_beam(flag, Vector3(-0.83, 3.78, 0), Vector3(0.83, 3.78, 0), 0.045, GOLD.darkened(0.2))
	var cloth_points := PackedVector3Array([
		Vector3(-0.72, 3.76, 0), Vector3(0.72, 3.76, 0), Vector3(0.75, 2.9, side * 0.18),
		Vector3(-0.72, 3.76, 0), Vector3(0.75, 2.9, side * 0.18), Vector3(-0.64, 2.9, side * 0.18),
		Vector3(-0.64, 2.9, side * 0.18), Vector3(0.75, 2.9, side * 0.18), Vector3(0.48, 1.4, side * 0.09),
		Vector3(-0.64, 2.9, side * 0.18), Vector3(0.48, 1.4, side * 0.09), Vector3(0.10, 1.72, side * 0.08),
		Vector3(-0.64, 2.9, side * 0.18), Vector3(0.10, 1.72, side * 0.08), Vector3(-0.56, 1.55, side * 0.09)
	])
	_polygon_mesh(flag, cloth_points, color)
	_box(flag, Vector3(0.02, 2.9, 0.20), Vector3(0.07, 1.15, 0.02), GOLD.darkened(0.12))
	_box(flag, Vector3(0.02, 3.08, 0.21), Vector3(0.60, 0.09, 0.02), GOLD.darkened(0.12))
	_box(flag, Vector3(0.02, 2.64, 0.21), Vector3(0.40, 0.07, 0.02), GOLD.darkened(0.12))


func _rock(pos: Vector3, size_factor: float) -> void:
	var rock := _sphere(_room, pos + Vector3.UP * size_factor * 0.37, size_factor, Color("354943").lightened(_rng.randf_range(0.0, 0.08)), 5)
	rock.scale = Vector3(1.35, 0.72, 0.85)
	rock.rotation = Vector3(_rng.randf_range(-0.25, 0.25), _rng.randf_range(0, TAU), 0)


func _player_cloak(parent: Node3D) -> void:
	_cape(parent, Color("a33c30"), 0.50, 1.42, 0.38)
	# A second layer makes the red travel cloak visible both from behind and from above.
	var collar := _cylinder(parent, Vector3(0, 1.34, 0.045), 0.28, 0.37, 0.15, Color("bb4f35"), 10)
	collar.scale.z = 0.92
	_box(parent, Vector3(-0.18, 1.14, -0.257), Vector3(0.15, 0.48, 0.08), Color("993b31"))


func _cape(parent: Node3D, color: Color, width: float, top: float, bottom: float) -> void:
	var points := PackedVector3Array([
		Vector3(-width * 0.66, top, 0.12), Vector3(width * 0.66, top, 0.12), Vector3(0, bottom - 0.03, 0.54),
		Vector3(-width * 0.66, top, 0.12), Vector3(0, bottom - 0.03, 0.54), Vector3(-width, bottom + 0.05, 0.39),
		Vector3(width * 0.66, top, 0.12), Vector3(width, bottom + 0.08, 0.40), Vector3(0, bottom - 0.03, 0.54)
	])
	_polygon_mesh(parent, points, color)
	_beam(parent, Vector3(-width * 0.66, top, 0.135), Vector3(-width, bottom + 0.05, 0.40), 0.013, GOLD.darkened(0.15))
	_beam(parent, Vector3(width * 0.66, top, 0.135), Vector3(width, bottom + 0.08, 0.41), 0.013, GOLD.darkened(0.15))


func _material(color: Color, emission: float = 0.0, double_sided: bool = false) -> Material:
	var key: String = color.to_html() + ":" + str(emission) + ":" + str(double_sided)
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	if double_sided:
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = material
	return material


func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(parent, mesh, pos, color, emission)


func _cylinder(parent: Node3D, pos: Vector3, top: float, bottom: float, height: float, color: Color, sides: int = 12, emission: float = 0.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	return _mesh(parent, mesh, pos, color, emission)


func _sphere(parent: Node3D, pos: Vector3, radius: float, color: Color, sides: int = 10, emission: float = 0.0) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = sides
	mesh.rings = maxi(3, sides / 2)
	return _mesh(parent, mesh, pos, color, emission)


func _torus(parent: Node3D, pos: Vector3, inner: float, outer: float, color: Color, rotation_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 40
	mesh.ring_segments = 6
	var instance: MeshInstance3D = _mesh(parent, mesh, pos, color)
	instance.rotation = rotation_value
	return instance


func _beam(parent: Node3D, from: Vector3, to: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var offset: Vector3 = to - from
	var beam: MeshInstance3D = _cylinder(parent, (from + to) * 0.5, radius * 0.77, radius, offset.length(), color, 6)
	var direction: Vector3 = offset.normalized()
	var axis: Vector3 = Vector3.UP.cross(direction)
	if axis.length_squared() > 0.00001:
		beam.basis = Basis(axis.normalized(), acos(clampf(Vector3.UP.dot(direction), -1.0, 1.0)))
	elif direction.y < 0:
		beam.rotation.x = PI
	return beam


func _mesh(parent: Node3D, geometry: Mesh, pos: Vector3, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = geometry
	instance.material_override = _material(color, emission)
	instance.position = pos
	parent.add_child(instance)
	return instance


func _polygon_mesh(parent: Node3D, vertices: PackedVector3Array, color: Color) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in vertices:
		surface.add_vertex(vertex)
	surface.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh = surface.commit()
	instance.material_override = _material(color, 0.0, true)
	parent.add_child(instance)
	return instance
