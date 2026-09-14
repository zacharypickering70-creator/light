extends RefCounted

const CHARGE_WINDUP := 0.90
const CHARGE_RECOVERY := 1.05
const CHARGE_SPEED := 11.0
# Includes the player's collision allowance; the visible capsule is the hit area.
const CHARGE_RADIUS := 1.20
const RETREAT_DURATION := 0.58

static func handles(enemy: Dictionary) -> bool:
	return enemy.get("kind", "") in ["grunt", "ranger", "brute"]

static func initialize(enemy: Dictionary, spawn_index: int, map_seed: int) -> void:
	if not handles(enemy): return
	var random := RandomNumberGenerator.new()
	random.seed = map_seed + spawn_index * 8191 + 27183
	enemy["flank_side"] = [0.0, 1.0, 0.0, -1.0][posmod(spawn_index + map_seed, 4)]
	enemy["retreat_cooldown"] = random.randf_range(0.0, 0.9)
	enemy["charge_cooldown"] = random.randf_range(2.5, 4.0)
	enemy["tactic_phase"] = random.randf_range(0.0, 0.8)

static func tick(g: Node, enemy: Dictionary, dt: float) -> void:
	if not handles(enemy) or float(enemy.get("hp", 0.0)) <= 0.0: return
	if float(enemy.get("stun", 0.0)) > 0.0:
		interrupt(enemy)
		return
	enemy["retreat_cooldown"] = maxf(0.0, float(enemy.get("retreat_cooldown", 0.0)) - dt)
	enemy["charge_cooldown"] = maxf(0.0, float(enemy.get("charge_cooldown", 0.0)) - dt)
	enemy["timer"] = float(enemy["timer"]) - dt
	var mode: String = enemy["mode"]
	if mode == "charge_tell":
		# A displacement breaks the committed stance rather than snapping back to its old path.
		if enemy["node"].position.distance_to(enemy["charge_from"]) > 0.12:
			interrupt(enemy)
		elif enemy["timer"] <= 0.0:
			enemy["mode"] = "charge"
			enemy["timer"] = enemy["charge_from"].distance_to(enemy["charge_to"]) / CHARGE_SPEED
			enemy["charge_last"] = enemy["node"].position
		return
	if mode == "charge":
		_tick_charge(g, enemy, dt)
		return
	if mode in ["recover", "charge_recover"]:
		if enemy["timer"] <= 0.0: enemy["mode"] = "chase"
		return
	var node: Node3D = enemy["node"]
	var diff: Vector3 = g.player.position - node.position
	diff.y = 0.0
	var distance: float = diff.length()
	var forward: Vector3 = diff.normalized() if distance > 0.01 else Vector3.FORWARD
	if distance > 0.01:
		node.rotation.y = lerp_angle(node.rotation.y, atan2(-diff.x, -diff.z), minf(1.0, dt * 7.0))
	if mode == "tell":
		if is_instance_valid(enemy.get("tell")):
			enemy["tell"].scale = Vector3.ONE * (0.94 + sin(g.start_time * 20.0) * 0.04)
		if enemy["timer"] <= 0.0: g._resolve_enemy_attack(enemy)
		return
	if mode == "retreat":
		var before: Vector3 = node.position
		_move(g, enemy, enemy["retreat_direction"], dt, 1.05)
		if enemy["timer"] <= 0.0 or node.position.distance_to(before) < 0.005:
			enemy["mode"] = "chase"
			enemy["timer"] = 0.12
		return
	if enemy["kind"] == "ranger":
		if distance < 3.4 and enemy["retreat_cooldown"] <= 0.0:
			enemy["mode"] = "retreat"
			enemy["timer"] = RETREAT_DURATION
			enemy["retreat_direction"] = -forward
			enemy["retreat_cooldown"] = 5.0 + float(enemy.get("tactic_phase", 0.0))
			return
		if distance > 5.0: _move(g, enemy, forward + _separation(g, enemy), dt)
		if distance < 7.0 and enemy["timer"] <= 0.0: g._telegraph(enemy)
		return
	if enemy["kind"] == "brute" and distance >= 3.2 and distance <= 8.0 and enemy["timer"] <= 0.0 and enemy["charge_cooldown"] <= 0.0:
		if begin_charge(g, enemy): return
	if distance > 1.1:
		var direction: Vector3 = pursuit_direction(enemy, diff) + _separation(g, enemy)
		_move(g, enemy, direction, dt)
	if distance < 2.1 and enemy["timer"] <= 0.0: g._telegraph(enemy)

static func pursuit_direction(enemy: Dictionary, diff: Vector3) -> Vector3:
	diff.y = 0.0
	var distance: float = diff.length()
	if distance < 0.01: return Vector3.ZERO
	var forward: Vector3 = diff / distance
	if enemy.get("kind", "") != "grunt": return forward
	# Half the swordsmen approach obliquely; all converge directly within melee range.
	var angle: float = float(enemy.get("flank_side", 0.0)) * 0.52 * clampf((distance - 3.0) / 4.0, 0.0, 1.0)
	return forward.rotated(Vector3.UP, angle)

static func _separation(g: Node, enemy: Dictionary) -> Vector3:
	var separation := Vector3.ZERO
	for other in g.enemies:
		if other == enemy or float(other["hp"]) <= 0.0: continue
		var away: Vector3 = enemy["node"].position - other["node"].position
		away.y = 0.0
		var length: float = away.length()
		if length < 1.2 and length > 0.01: separation += away / length * 0.65
	return separation

static func _move(g: Node, enemy: Dictionary, direction: Vector3, dt: float, speed_scale: float = 1.0) -> void:
	var node: Node3D = enemy["node"]
	var speed: float = float(enemy["speed"]) * speed_scale * (0.42 if float(enemy.get("slow", 0.0)) > 0.0 else 1.0)
	node.position = g.world.constrain_position(node.position + direction.limit_length(1.1) * speed * dt)

static func begin_charge(g: Node, enemy: Dictionary) -> bool:
	if enemy.get("kind", "") != "brute": return false
	var origin: Vector3 = enemy["node"].position
	var diff: Vector3 = g.player.position - origin
	diff.y = 0.0
	if diff.length() < 0.01: return false
	var direction: Vector3 = diff.normalized()
	var length: float = minf(6.0, diff.length() + 0.8)
	var end: Vector3 = origin
	# Stop before a wall or the arena rim. This scan only runs when committing a charge.
	for i in range(1, ceili(length / 0.2) + 1):
		var sample: Vector3 = origin + direction * minf(length, float(i) * 0.2)
		if g.world.constrain_position(sample).distance_to(sample) > 0.025: break
		end = sample
	if origin.distance_to(end) < 2.4:
		enemy["charge_cooldown"] = 1.0
		return false
	enemy["charge_from"] = origin
	enemy["charge_to"] = end
	enemy["charge_direction"] = direction
	enemy["charge_hit"] = false
	enemy["attack"] = "charge"
	enemy["mode"] = "charge_tell"
	enemy["timer"] = CHARGE_WINDUP
	enemy["charge_cooldown"] = 6.5 + float(enemy.get("tactic_phase", 0.0))
	enemy["count"] += 1
	enemy["node"].rotation.y = atan2(-direction.x, -direction.z)
	enemy["tell"] = _charge_warning(g, origin, end)
	return true

static func _tick_charge(g: Node, enemy: Dictionary, dt: float) -> void:
	var node: Node3D = enemy["node"]
	if node.position.distance_to(enemy["charge_last"]) > 0.12:
		interrupt(enemy)
		return
	var before: Vector3 = node.position
	var speed: float = CHARGE_SPEED * (0.42 if float(enemy.get("slow", 0.0)) > 0.0 else 1.0)
	var next: Vector3 = before.move_toward(enemy["charge_to"], speed * dt)
	if g.world.constrain_position(next).distance_to(next) > 0.025:
		interrupt(enemy)
		return
	node.position = next
	enemy["charge_last"] = next
	enemy["timer"] = next.distance_to(enemy["charge_to"]) / speed
	if not enemy["charge_hit"] and point_in_capsule(g.player.position, before, next, CHARGE_RADIUS):
		enemy["charge_hit"] = true
		g._hurt_player(20.0 * float(enemy.get("power", 1.0)) * (0.75 if float(enemy.get("weak", 0.0)) > 0.0 else 1.0), "brute_charge")
		if g.state != "playing" or float(enemy["hp"]) <= 0.0: return
	if next.distance_to(enemy["charge_to"]) < 0.01:
		interrupt(enemy)

static func interrupt(enemy: Dictionary) -> void:
	if not handles(enemy) or enemy.get("mode", "") not in ["charge_tell", "charge", "retreat"]: return
	var was_charge: bool = enemy["mode"] != "retreat"
	if is_instance_valid(enemy.get("tell")): enemy["tell"].queue_free()
	enemy["tell"] = null
	enemy["mode"] = "charge_recover" if was_charge else "recover"
	enemy["timer"] = CHARGE_RECOVERY if was_charge else 0.4

static func point_in_capsule(point: Vector3, from: Vector3, to: Vector3, radius: float) -> bool:
	var position := Vector2(point.x, point.z)
	var origin := Vector2(from.x, from.z)
	var end := Vector2(to.x, to.z)
	var path: Vector2 = end - origin
	var t: float = clampf((position - origin).dot(path) / path.length_squared(), 0.0, 1.0) if path.length_squared() > 0.00001 else 0.0
	return position.distance_squared_to(origin + path * t) <= radius * radius

static func _charge_warning(g: Node, origin: Vector3, end: Vector3) -> Node3D:
	var marker := MeshInstance3D.new()
	marker.name = "ChargeLane"
	marker.set_meta("from", origin)
	marker.set_meta("to", end)
	marker.set_meta("radius", CHARGE_RADIUS)
	var direction: Vector3 = (end - origin).normalized()
	marker.set_meta("direction", direction)
	var side: Vector3 = direction.cross(Vector3.UP)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3] = [origin + side * CHARGE_RADIUS, end + side * CHARGE_RADIUS, end - side * CHARGE_RADIUS, origin - side * CHARGE_RADIUS]
	for index in [0, 1, 2, 0, 2, 3]: surface.add_vertex(points[index] + Vector3.UP * 0.075)
	for cap in [origin, end]:
		for i in range(20):
			surface.add_vertex(cap + Vector3.UP * 0.075)
			for angle in [TAU * float(i) / 20.0, TAU * float(i + 1) / 20.0]:
				surface.add_vertex(cap + Vector3(cos(angle) * CHARGE_RADIUS, 0.075, sin(angle) * CHARGE_RADIUS))
	surface.generate_normals()
	marker.mesh = surface.commit()
	marker.material_override = g._material(Color(0.76, 0.22, 0.12, 0.32))
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.effects.add_child(marker)
	var arrow := MeshInstance3D.new()
	arrow.name = "LockedDirection"
	var arrow_surface := SurfaceTool.new()
	arrow_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tip: Vector3 = end - direction * 0.15 + Vector3.UP * 0.085
	for vertex in [tip, tip - direction * 0.95 + side * 0.65, tip - direction * 0.95 - side * 0.65]:
		arrow_surface.add_vertex(vertex)
	arrow_surface.generate_normals()
	arrow.mesh = arrow_surface.commit()
	arrow.material_override = g._material(Color(0.96, 0.53, 0.28, 0.88))
	arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.add_child(arrow)
	return marker
