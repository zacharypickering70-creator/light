extends RefCounted

const THEMES = ["渡口芦汀", "香火愿廊", "忘川旧市", "华山层岩", "莲心遗台", "城隍案牍"]
const PAPER = [Color("e0dbcc"), Color("ddd0b5"), Color("c6d5ce"), Color("d8ddd4"), Color("e1d2b8"), Color("ccd0bc")]
const FOG = [Color("e7e2d4"), Color("e3d6bd"), Color("b5cccb"), Color("d7dfda"), Color("e7d9c4"), Color("cbd0bb")]

static func dress(w: Node3D, id: int) -> void:
	if w.chapter < 2: return
	var detail := Node3D.new()
	detail.name = "ChapterDetails"
	detail.set_meta("theme", THEMES[w.chapter - 1])
	w._room.add_child(detail)
	var random := RandomNumberGenerator.new()
	random.seed = w.map_seed + w.chapter * 91009 + id * 701
	match w.chapter:
		2: _shrine(w, detail, id, random)
		3: _market(w, detail, id, random)
		4: _mountain(w, detail, id, random)
		5: _lotus(w, detail, id, random)
		6: _archive(w, detail, id, random)
	w._batch_static(detail)
	for mesh in detail.find_children("*", "MeshInstance3D", true, false):
		mesh.visibility_range_end = 48.0
		mesh.visibility_range_end_margin = 3.0

static func _shrine(w: Node3D, root: Node3D, id: int, random: RandomNumberGenerator) -> void:
	for side in [-1.0, 1.0]:
		var p := Vector3(side * 7.1, 0, -3.5)
		_urn(w, root, p, 1.15 if id == 6 else 0.85)
		var x: float = side * 6.9
		for post in [-1.4, 1.4]:
			w._beam(root, Vector3(x + post, 0, -6.5), Vector3(x + post, 2.6, -6.5), 0.075, Color("665442"))
		w._beam(root, Vector3(x - 1.4, 2.55, -6.5), Vector3(x + 1.4, 2.5, -6.5), 0.023, Color("8b7857"))
		for j in range(7):
			var pos := Vector3(x - 1.2 + j * 0.4, 1.9 + random.randf_range(-0.13, 0.13), -6.5)
			w._beam(root, pos + Vector3.UP * 0.26, pos + Vector3.UP * 0.63, 0.012, Color("994334"))
			var plaque: MeshInstance3D = w._box(root, pos, Vector3(0.30, 0.56, 0.06), Color("cbb085"))
			plaque.rotation.x = random.randf_range(-0.10, 0.10)
			for line in range(3):
				w._box(root, pos + Vector3(0, 0.16 - line * 0.13, 0.040), Vector3(0.17, 0.035, 0.012), Color("665442"))
		for j in range(5):
			var tile := Vector3(side * (5.5 + random.randf()), 0.073, 0.2 + j * 0.62)
			var paper: MeshInstance3D = w._box(root, tile, Vector3(0.28, 0.008, 0.46), Color("c8b98b"))
			paper.rotation.y = random.randf_range(-0.7, 0.7)
	if id == 6:
		for x in [-4.0, -2.0, 2.0, 4.0]:
			w._box(root, Vector3(x, 0.11, -5.4), Vector3(1.4, 0.08, 0.9), Color("a89470"))

static func _urn(w: Node3D, root: Node3D, pos: Vector3, size: float) -> void:
	var urn := Node3D.new()
	root.add_child(urn)
	urn.position = pos
	urn.scale = Vector3.ONE * size
	w._cylinder(urn, Vector3(0, 0.58, 0), 0.64, 0.4, 0.67, Color("6c745f"), 10)
	w._cylinder(urn, Vector3(0, 0.93, 0), 0.58, 0.58, 0.06, Color("b2a17a"), 10)
	w._cylinder(urn, Vector3(0, 0.97, 0), 0.49, 0.49, 0.015, Color("59594d"), 10)
	for side in [-1.0, 1.0]:
		w._beam(urn, Vector3(side * 0.2, 0.04, 0.24), Vector3(side * 0.3, 0.48, 0.24), 0.09, Color("6c745f"))
		w._beam(urn, Vector3(side * 0.5, 0.63, 0), Vector3(side * 0.83, 0.8, 0), 0.07, Color("6c745f"))
		w._beam(urn, Vector3(side * 0.83, 0.8, 0), Vector3(side * 0.7, 1.18, 0), 0.06, Color("6c745f"))
	for i in range(5):
		var p := Vector3(-0.22 + i * 0.11, 0.98, (i % 2) * 0.15)
		w._beam(urn, p, p + Vector3((i - 2) * 0.06, 0.65, 0), 0.017, Color("994334"))

static func _market(w: Node3D, root: Node3D, id: int, random: RandomNumberGenerator) -> void:
	for side in [-1.0, 1.0]:
		_stall(w, root, Vector3(side * 3.15, 0, -8.2), id + (1 if side > 0 else 0))
		for j in range(6):
			var p := Vector3(side * 6.05 + random.randf_range(-0.65, 0.65), 0.13, -6.5 + j * 2.25)
			w._box(root, p, Vector3(0.48, 0.10, 0.43), Color("5b726b"))
			w._cylinder(root, p + Vector3.UP * 0.18, 0.14, 0.21, 0.28, Color("d7c993"), 6)
			w._cylinder(root, p + Vector3.UP * 0.36, 0.032, 0.09, 0.13, Color("c98851"), 5, 1.0)
		for j in range(6):
			w._box(root, Vector3(side * 4.62, 0.10, -6 + j * 2.2), Vector3(0.24, 0.15, 1.65), Color("728e89"))
	if id in [3, 5, 6]:
		for j in range(4):
			var p := Vector3(-1.4 + j * 0.9, 0.073, 4.4 + (j % 2) * 0.6)
			w._box(root, p, Vector3(0.56, 0.01, 0.86), Color("b9c5b5"))
			w._box(root, p + Vector3(0, 0.012, 0.05), Vector3(0.035, 0.008, 0.46), Color("607c79"))

static func _stall(w: Node3D, root: Node3D, pos: Vector3, variant: int) -> void:
	var booth := Node3D.new()
	root.add_child(booth)
	booth.position = pos
	var cloth: Color = Color("698d87") if variant % 2 == 0 else Color("9b8b75")
	for x in [-1.22, 1.22]:
		for z in [-0.75, 0.75]:
			w._beam(booth, Vector3(x, 0, z), Vector3(x, 2.6, z), 0.055, Color("576b60"))
	for side in [-1.0, 1.0]:
		w._polygon_mesh(booth, PackedVector3Array([Vector3(-1.5, 2.62, side), Vector3(1.5, 2.62, side), Vector3(1.5, 3.13, 0), Vector3(-1.5, 2.62, side), Vector3(1.5, 3.13, 0), Vector3(-1.5, 3.13, 0)]), cloth)
		for j in range(5):
			w._box(booth, Vector3(-1.25 + j * 0.63, 2.47, side), Vector3(0.43, 0.28, 0.025), cloth)
	w._box(booth, Vector3(0, 0.93, 0.15), Vector3(2.7, 0.16, 1.2), Color("7c8370"))
	for x in [-1.0, 1.0]: w._box(booth, Vector3(x, 0.46, 0.15), Vector3(0.14, 0.9, 0.8), Color("576b60"))
	for j in range(5):
		var p := Vector3(-0.95 + j * 0.46, 1.11, 0.2)
		if variant % 2 == 0:
			w._cylinder(booth, p, 0.12, 0.20, 0.22, Color("ccd1b7"), 8)
		else:
			var roll: MeshInstance3D = w._cylinder(booth, p, 0.10, 0.10, 0.62, Color("c8bd97"), 8)
			roll.rotation.x = PI / 2

static func _mountain(w: Node3D, root: Node3D, id: int, random: RandomNumberGenerator) -> void:
	for side in [-1.0, 1.0]:
		var origin := Vector3(side * 9.7, 0, -1.5)
		for layer in range(4):
			var rock: MeshInstance3D = w._cylinder(root, origin + Vector3(side * layer * 0.18, layer * 0.62 + 0.15, -layer * 0.10), 1.05 - layer * 0.14, 1.8 - layer * 0.21, 0.8, Color("82958a").lightened(layer * 0.04), 5)
			rock.scale.z = 1.9
			rock.rotation.y = side * 0.22
		_pine(w, root, origin + Vector3(side * 0.15, 2.45, -0.25), side)
		for j in range(3):
			var vein: MeshInstance3D = w._box(root, Vector3(side * (6 + j * 0.55), 0.077, 3 + j * 0.7), Vector3(1.5, 0.008, 0.09), Color("99aaa0"))
			vein.rotation.y = side * 0.5 + random.randf_range(-0.15, 0.15)
	if id in [3, 5, 6]:
		for side in [-1.0, 1.0]:
			w._beam(root, Vector3(side * 6.5, 0.8, -6.5), Vector3(side * 8.6, 1.3, -7.0), 0.033, Color("62756f"))

static func _pine(w: Node3D, root: Node3D, pos: Vector3, side: float) -> void:
	var a: Vector3 = pos + Vector3(side * 0.5, 1.1, 0)
	var b: Vector3 = pos + Vector3(side * 1.25, 2.0, -0.2)
	w._beam(root, pos, a, 0.16, Color("5a675b"))
	w._beam(root, a, b, 0.10, Color("5a675b"))
	for j in range(3):
		var center: Vector3 = a.lerp(b, j * 0.43) + Vector3(side * (0.5 + j * 0.1), 0.15, (j % 2 - 0.5) * 0.75)
		w._beam(root, a.lerp(b, j * 0.4), center, 0.045, Color("5a675b"))
		var crown: MeshInstance3D = w._cylinder(root, center, 0.4, 1.0, 0.25, Color("526f5e"), 7)
		crown.scale = Vector3(1.2, 1, 0.72)
		for k in range(4):
			var needle := center + Vector3(-0.75 + k * 0.45, 0.05, 0)
			w._beam(root, needle, needle + Vector3(0.35, 0.20, 0.18), 0.022, Color("8f9e7d"))

static func _lotus(w: Node3D, root: Node3D, id: int, random: RandomNumberGenerator) -> void:
	var radius: float = 4.9 if id == 6 else 3.1
	for i in range(8):
		var angle: float = i * TAU / 8.0
		var outward := Vector3(cos(angle), 0, sin(angle))
		var side := Vector3(-sin(angle), 0, cos(angle))
		var base: Vector3 = outward * radius + Vector3.UP * (0.23 if id == 6 else 0.078)
		var points := PackedVector3Array([base, base + outward * 0.80 + side * 0.32, base + outward * 1.85, base, base + outward * 1.85, base + outward * 0.80 - side * 0.32])
		w._polygon_mesh(root, points, Color("aa826c"))
		w._beam(root, base + Vector3.UP * 0.006, base + outward * 1.60 + Vector3.UP * 0.006, 0.017, Color("d9c18b"))
	for side in [-1.0, 1.0]:
		var p := Vector3(side * 7.2, 0, -5.4)
		w._cylinder(root, p + Vector3.UP * 0.23, 0.66, 0.85, 0.46, Color("b7a48a"), 8)
		w._cylinder(root, p + Vector3.UP * 0.78, 0.2, 0.36, 0.8, Color("9c927b"), 8)
		for i in range(6):
			var angle: float = i * TAU / 6.0
			var petal: MeshInstance3D = w._sphere(root, p + Vector3(cos(angle) * 0.28, 1.18, sin(angle) * 0.28), 0.26, Color("cab393"), 6)
			petal.scale = Vector3(0.65, 0.55, 1.7)
			petal.rotation.y = PI / 2 - angle
		w._cylinder(root, p + Vector3.UP * 1.43, 0.03, 0.12, 0.25, Color("c88954"), 6, 1)
	for i in range(12):
		var angle: float = random.randf() * TAU
		var p := Vector3(cos(angle), 0, sin(angle)) * random.randf_range(6.2, 7.8)
		p.y = 0.075
		w._polygon_mesh(root, PackedVector3Array([p, p + Vector3(0.17, 0.014, 0.2), p + Vector3(0.43, 0.015, 0.09)]), Color("bc9b81"))

static func _archive(w: Node3D, root: Node3D, id: int, random: RandomNumberGenerator) -> void:
	for side in [-1.0, 1.0]:
		var p := Vector3(side * 6.5, 0, -7.0)
		w._box(root, p + Vector3.UP * 1.1, Vector3(2.5, 2.2, 0.85), Color("655f4d"))
		for row in range(4):
			for col in range(4):
				var slot: Vector3 = p + Vector3(-0.9 + col * 0.60, 0.32 + row * 0.5, 0.45)
				w._box(root, slot, Vector3(0.51, 0.40, 0.065), Color("948968"))
				w._box(root, slot + Vector3(0, 0.04, 0.04), Vector3(0.25, 0.11, 0.018), Color("c9bf98"))
				w._box(root, slot + Vector3(0, -0.09, 0.06), Vector3(0.12, 0.035, 0.07), Color("655f4d"))
		var desk := p + Vector3(-side * 0.45, 0, 2.3)
		w._box(root, desk + Vector3.UP * 0.86, Vector3(2.0, 0.16, 1.0), Color("766b51"))
		for x in [-0.82, 0.82]: w._box(root, desk + Vector3(x, 0.4, 0), Vector3(0.15, 0.8, 0.75), Color("655f4d"))
		for j in range(3):
			w._box(root, desk + Vector3(-0.48 + j * 0.43, 0.99 + (j % 2) * 0.04, 0), Vector3(0.35, 0.06, 0.64), Color("c9bf98"))
		w._cylinder(root, desk + Vector3(0.65, 1.02, 0.18), 0.13, 0.13, 0.16, Color("994334"), 6)
		for j in range(5):
			var page := Vector3(side * (4.9 + random.randf() * 1.9), 0.075, -1.0 + j * 0.73)
			var sheet: MeshInstance3D = w._box(root, page, Vector3(0.42, 0.01, 0.62), Color("c9bf98"))
			sheet.rotation.y = random.randf_range(-0.7, 0.7)
			w._box(root, page + Vector3(0, 0.012, 0.16), Vector3(0.13, 0.008, 0.13), Color("994334"))
	if id == 6:
		for x in [-4.6, 4.6]:
			w._beam(root, Vector3(x, 0, -3.7), Vector3(x, 3.2, -3.7), 0.07, Color("655f4d"))
			w._box(root, Vector3(x, 2.13, -3.7), Vector3(0.80, 1.75, 0.035), Color("c9bf98"))
			for j in range(4): w._box(root, Vector3(x, 2.68 - j * 0.36, -3.665), Vector3(0.31, 0.11, 0.015), Color("655f4d"))
