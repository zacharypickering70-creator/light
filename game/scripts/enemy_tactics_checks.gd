extends SceneTree

const Tactics = preload("res://scripts/enemy_tactics.gd")
var failures: Array[String] = []
var g: Node
var serial := 0

func _initialize(): call_deferred("run")
func check(value: bool, message: String):
	if not value: failures.append(message)

func spawn(kind: String, pos: Vector3) -> Dictionary:
	var enemy: Dictionary = g._spawn_enemy(kind, pos)
	Tactics.initialize(enemy, serial, 7319)
	serial += 1
	return enemy

func clear_enemies() -> void:
	for enemy in g.enemies:
		if is_instance_valid(enemy.get("tell")): enemy["tell"].free()
		if is_instance_valid(enemy["node"]): enemy["node"].free()
	g.enemies.clear()

func health_reset() -> void:
	g.state = "playing"
	g.journey_started = true
	g.hp = 500.0
	g.max_hp = 500.0
	g.immunity = 0.0
	g.shield_hp = 0.0
	g.guard_left = 0.0
	g.boon_counts.clear()
	g.passives.clear()
	g.progress["equipped"]["robe"] = "pilgrim_robe"
	g.progress["gear"]["robe"] = 0
	g.damage_sources.clear()

func charge_at(point: Vector3, power: float = 1.0, weak: float = 0.0) -> Dictionary:
	clear_enemies()
	health_reset()
	g.player.position = Vector3.ZERO
	var enemy: Dictionary = spawn("brute", Vector3(0, 0, 5))
	enemy["power"] = power
	enemy["weak"] = weak
	check(Tactics.begin_charge(g, enemy), "charge can commit in open ground")
	g.player.position = point
	Tactics.tick(g, enemy, Tactics.CHARGE_WINDUP)
	check(enemy["mode"] == "charge", "full windup precedes movement")
	return enemy

func run():
	g = load("res://main.tscn").instantiate()
	root.add_child(g)
	g.set_process(false)
	g.test_mode = true
	g.music_player.stop()
	g._start_run()
	g._on_action("begin")
	g._depart()
	clear_enemies()
	g.world.obstacles.clear()
	health_reset()
	var original_rng: int = g.rng.state
	for i in range(16):
		var a: Dictionary = {"kind":"grunt"}
		var b: Dictionary = {"kind":"grunt"}
		Tactics.initialize(a, i, 8821)
		Tactics.initialize(b, i, 8821)
		check(a == b, "identical seed and serial repeat tactical assignment")
		var aim: Vector3 = Tactics.pursuit_direction(a, Vector3(0, 0, -8))
		check(aim.dot(Vector3.FORWARD) > 0.86, "flank still advances toward player")
		check(Tactics.pursuit_direction(a, Vector3(0, 0, -2)).is_equal_approx(Vector3.FORWARD), "flank stops before melee range")
	check(g.rng.state == original_rng, "tactic setup does not consume loot or wave RNG")
	check(Tactics.pursuit_direction({"kind":"grunt"}, Vector3.ZERO) == Vector3.ZERO, "coincident positions produce no invalid vector")
	var boss: Dictionary = {"kind":"boss", "mode":"tell", "timer":1.0, "hp":100.0}
	var boss_before: Dictionary = boss.duplicate(true)
	Tactics.initialize(boss, 1, 8821)
	Tactics.tick(g, boss, 0.5)
	Tactics.interrupt(boss)
	check(boss == boss_before, "boss state is completely outside small-enemy tactics")
	var grunt: Dictionary = spawn("grunt", Vector3(0, 0, 10))
	grunt["flank_side"] = 1.0
	grunt["timer"] = 10.0
	g.player.position = Vector3.ZERO
	for i in range(55): Tactics.tick(g, grunt, 0.05)
	check(grunt["node"].position.length() < 2.1, "flanking swordsman reaches melee within 2.75 seconds")
	clear_enemies()
	var ranger: Dictionary = spawn("ranger", Vector3(0, 0, 2))
	ranger["retreat_cooldown"] = 0.0
	ranger["timer"] = 0.0
	Tactics.tick(g, ranger, 0.01)
	check(ranger["mode"] == "retreat", "close ranger retreats in a readable burst")
	var retreat_from: Vector3 = ranger["node"].position
	for i in range(12): Tactics.tick(g, ranger, 0.05)
	check(ranger["mode"] == "chase", "retreat expires rather than endlessly kiting")
	check(ranger["node"].position.distance_to(retreat_from) < 2.4, "retreat covers less than one short dash")
	g.player.position = ranger["node"].position + Vector3.FORWARD * 2.0
	Tactics.tick(g, ranger, 0.2)
	check(ranger["mode"] == "tell", "pursued ranger stands to cast while retreat is cooling down")
	var cast_from: Vector3 = ranger["node"].position
	Tactics.tick(g, ranger, 0.1)
	check(ranger["node"].position == cast_from, "ranger cannot shoot while retreating")
	clear_enemies()
	ranger = spawn("ranger", Vector3(g.world.map_radius - 0.1, 0, 0))
	ranger["retreat_cooldown"] = 0.0
	g.player.position = ranger["node"].position - Vector3.RIGHT * 2.0
	Tactics.tick(g, ranger, 0.01)
	for i in range(12): Tactics.tick(g, ranger, 0.05)
	check(ranger["node"].position.length() <= g.world.map_radius + 0.001, "retreat respects map rim")
	check(ranger["mode"] != "retreat", "blocked retreat yields a punishable stop")
	var brute: Dictionary = charge_at(Vector3(2, 0, 0))
	var warning: Node3D = brute["tell"]
	check(warning.get_meta("from") == brute["charge_from"] and warning.get_meta("to") == brute["charge_to"], "warning and movement share locked endpoints")
	check(is_equal_approx(warning.get_meta("radius"), Tactics.CHARGE_RADIUS), "visible warning uses collision radius")
	check(warning.has_node("LockedDirection") and warning.get_meta("direction") == brute["charge_direction"], "warning arrow matches the committed direction")
	var locked_direction: Vector3 = brute["charge_direction"]
	for i in range(10): Tactics.tick(g, brute, 0.1)
	check(g.hp == 500.0, "sidestepping the locked lane avoids damage")
	check(brute["charge_direction"] == locked_direction, "charge never tracks a sidestepping player")
	check(brute["mode"] == "charge_recover", "charge ends with a punishable recovery")
	brute = charge_at(Vector3.ZERO, 2.0, 3.0)
	Tactics.tick(g, brute, 0.6)
	check(is_equal_approx(g.hp, 470.0), "swept charge catches a long frame and preserves base damage, scaling and weaken")
	check(g.last_damage_source == "1:brute_charge", "charge damage remains attributable")
	g.immunity = 0.0
	Tactics.tick(g, brute, 0.01)
	check(is_equal_approx(g.hp, 470.0), "one charge never deals contact damage twice")
	brute = charge_at(Vector3(0, 0, 3.5))
	Tactics.tick(g, brute, 0.04)
	for i in range(6):
		g.immunity = 0.0
		g.player.position = brute["node"].position + Vector3.FORWARD * 0.5
		Tactics.tick(g, brute, 0.03)
	check(brute["mode"] == "charge", "repeated-contact check stays inside an unfinished charge")
	check(g.hp == 480.0 and g.damage_sources["1:brute_charge"]["hits"] == 1, "repeated contact hits once even when player immunity is removed")
	brute = charge_at(Vector3.ZERO)
	g.immunity = 0.5
	Tactics.tick(g, brute, 0.6)
	check(g.hp == 500.0, "dash immunity blocks charge damage through the existing damage path")
	brute = charge_at(Vector3.ZERO)
	brute["stun"] = 1.0
	Tactics.tick(g, brute, 0.1)
	check(brute["mode"] == "charge_recover" and brute["tell"] == null, "control interrupts charge and removes its warning")
	check(g.hp == 500.0, "interrupted charge cannot hit")
	brute = charge_at(Vector3.ZERO)
	brute["node"].position += Vector3.RIGHT * 0.22
	Tactics.tick(g, brute, 0.1)
	check(brute["mode"] == "charge_recover", "weapon displacement breaks charge instead of snapping the enemy back")
	clear_enemies()
	g.player.position = Vector3.ZERO
	brute = spawn("brute", Vector3(0, 0, 5))
	g.world.obstacles.assign([{"pos":Vector3(0, 0, 1), "radius":0.5}])
	check(Tactics.begin_charge(g, brute), "charge can shorten before an obstacle")
	check(brute["charge_to"].z >= 1.9, "locked charge stops before obstacle collision boundary")
	Tactics.interrupt(brute)
	g.world.obstacles.assign([{"pos":Vector3(0, 0, 3), "radius":0.5}])
	check(not Tactics.begin_charge(g, brute), "insufficient clear run falls back to normal melee pursuit")
	g.world.obstacles.clear()
	brute["node"].position = Vector3(g.world.map_radius - 3.0, 0, 0)
	g.player.position = Vector3(g.world.map_radius + 4.0, 0, 0)
	check(Tactics.begin_charge(g, brute), "rim-facing charge is bounded")
	check(brute["charge_to"].length() <= g.world.map_radius + 0.001, "charge endpoint remains in map")
	check(Tactics.point_in_capsule(Vector3(1.19, 99, 2), Vector3.ZERO, Vector3(0, 0, 4), 1.2), "capsule uses ground-plane distance")
	check(not Tactics.point_in_capsule(Vector3(1.21, 0, 2), Vector3.ZERO, Vector3(0, 0, 4), 1.2), "outside visible capsule cannot hit")
	check(Tactics.point_in_capsule(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, 1.2), "zero-length sweep handles coincident endpoints")
	clear_enemies()
	health_reset()
	g.hp = 50000.0
	g.max_hp = 50000.0
	g.player.position = Vector3.ZERO
	var brutes := 0
	for i in range(65):
		var kind: String = ["grunt", "ranger", "brute"][i % 3]
		var angle: float = TAU * float(i) / 65.0
		var radius: float = 12.0 + float(i % 4) * 2.0
		var enemy: Dictionary = spawn(kind, Vector3(cos(angle), 0, sin(angle)) * radius)
		if kind == "brute": brutes += 1
	var charge_peak := 0
	var committed_peak := 0
	for frame in range(160):
		g.start_time += 0.05
		g.immunity = maxf(0.0, g.immunity - 0.05)
		var charging := 0
		var committed := 0
		for enemy in g.enemies:
			g._tick_enemy(enemy, 0.05)
			if enemy["mode"] == "charge": charging += 1
			if enemy["mode"] in ["charge", "charge_tell"]: committed += 1
			check(enemy["node"].position.is_finite() and enemy["node"].position.length() <= g.world.map_radius + 0.001, "65-enemy movement remains finite and inside the arena")
		charge_peak = maxi(charge_peak, charging)
		committed_peak = maxi(committed_peak, committed)
	var near_grunts := 0
	for enemy in g.enemies:
		if enemy["kind"] == "grunt" and enemy["node"].position.length() < 6.0: near_grunts += 1
	check(g.enemies.size() == 65, "mixed cohort retains the requested full 65-enemy cap")
	check(near_grunts >= 20, "crowded swordsmen close in instead of orbiting indefinitely")
	check(charge_peak > 0 and committed_peak < brutes, "mixed brutes charge in staggered commitments")
	print("TACTICS_DENSITY ", JSON.stringify({"enemies":65, "seconds":8.0, "near_grunts":near_grunts, "brutes":brutes, "charge_peak":charge_peak, "committed_peak":committed_peak}))
	clear_enemies()
	print("ENEMY_TACTICS_PASS" if failures.is_empty() else "ENEMY_TACTICS_FAIL " + str(failures))
	quit(0 if failures.is_empty() else 1)
