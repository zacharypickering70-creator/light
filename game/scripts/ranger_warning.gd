extends RefCounted

static func draw(g: Node, enemy: Dictionary) -> void:
	var direction: Vector3 = enemy["aim"] - enemy["node"].position
	direction.y = 0
	direction = direction.normalized() if direction.length() > 0.01 else Vector3.FORWARD
	var angles: Array = [-0.22, 0.0, 0.22] if enemy.get("fan_shot", false) else [0.0]
	for angle in angles:
		var aim: Vector3 = direction.rotated(Vector3.UP, angle)
		var mark := MeshInstance3D.new()
		var line := BoxMesh.new()
		line.size = Vector3(0.10, 0.025, 12.0)
		mark.mesh = line
		mark.material_override = g._material(Color(0.82, 0.23, 0.09, 0.55))
		enemy["tell"].add_child(mark)
		mark.position = aim * 6.0 + Vector3.UP * 0.06
		mark.rotation.y = atan2(aim.x, aim.z)
