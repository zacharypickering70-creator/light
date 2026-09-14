extends SceneTree
var failures: Array[String]=[]
func _initialize(): call_deferred("run")
func check(ok: bool, reason: String):
	if not ok: failures.append(reason)
func run():
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	g.set_process(false)
	g.test_mode=true
	g.music_player.stop()
	g._start_run()
	g.state="playing"
	g.ui.hide_modal()
	g.player.position=Vector3.ZERO
	g.facing=Vector3.FORWARD
	var front: Dictionary=g._spawn_enemy("brute",Vector3(0,0,-2.5))
	var rear: Dictionary=g._spawn_enemy("brute",Vector3(0,0,2.0))
	check(g._attack_target(3.2)==front,"front target preferred over similar rear distance")
	front["node"].position=Vector3(0,0,-8)
	check(g._attack_target(3.2)==rear,"unreachable target does not steal aim")
	front["node"].position=Vector3(-0.1,0,-2.5)
	rear["node"].position=Vector3(0.1,0,-2.4)
	g.aim_target_id=front["node"].get_instance_id()
	g.aim_memory=0.3
	check(g._attack_target(3.2)==front,"small distance fluctuations retain combo target")
	g._test_clear_enemies()
	g._spawn_enemy("brute",Vector3(0,0,-2))
	g._attack()
	check(g.hit_stop>0 and not g.weapon_tween.is_running(),"weapon freezes on contact")
	g.ui.move_vector=Vector2.RIGHT
	var before: Vector3=g.player.position
	g._tick_game(0.016)
	check(g.player.position.x>before.x,"movement stays live through impact")
	g.hit_stop=0
	g._sync_weapon_impact()
	check(g.weapon_tween.is_running(),"weapon resumes after contact")
	g.ui.move_vector=Vector2.ZERO
	g._test_clear_enemies()
	g.dash_left=0
	g.cast_pose=0
	g.learned_skills.assign(["fire","frost","thunder"])
	g.skill_ranks={"fire":1,"frost":1,"thunder":1}
	g.skill_cds.assign([0.0,0.0,0.0])
	g.energy=100
	var aura: Node3D=g.player.get_node("LoadoutAura")
	var socket: Node3D=g.player.get_node("Body/RightArm/Grip/Weapon")
	var weapon_id: int=socket.get_child(0).get_instance_id()
	g._request_skill(0)
	g._request_skill(1)
	g._request_skill(2)
	check(g.skill_cds[0]>0 and g.skill_cds[1]==0 and g.skill_cds[2]==0,"simultaneous taps preserve separate casting beats")
	for i in range(9): g._tick_game(0.02)
	check(g.skill_cds[2]>0 and g.skill_cds[1]==0,"latest queued skill follows once")
	check(g.player.get_node("LoadoutAura")==aura,"casting reuses equipped aura")
	check(socket.get_child(0).get_instance_id()==weapon_id,"casting does not rebuild equipped weapon")
	check(aura.get_node("SkillSeal").modulate==Color(Color(g.Techniques.SKILLS["thunder"]["color"]),0.4),"reused aura follows active skill")
	g.guard_left=0
	g.shield_hp=0
	g.haste_left=3
	g._tick_buffs(0.02)
	check(aura.get_node("StatusSeal").modulate==Color("a4e1be"),"buff color follows current status")
	g.dash_cd=0
	g._request_dash(Vector3.LEFT)
	check(g.dash_left>0 and g.cast_pose==0,"dash cancels casting posture immediately")
	g.dash_left=0
	g.cast_pose=0
	g.attack_cd=0
	g._attack()
	g.ultimate_cd=0
	g.ultimate_charge=100
	g._ultimate()
	check(g.attack_pose==0 and g.cast_pose>0 and g.ultimate_charge==0,"ultimate replaces swing posture")
	g.skill_cds[1]=0
	g.energy=100
	g._request_skill(1)
	for i in range(14): g._tick_game(0.02)
	check(g.skill_cds[1]>0,"skill input survives ultimate recovery")
	g.passives.assign(["spark","focus"])
	g._refresh_gear_visual()
	var charms: Array[Node]=g.player.get_node("LoadoutAura").find_children("MindCharm*","Sprite3D",true,false)
	check(charms.size()==2,"equipping minds refreshes cached charms")
	check(charms[0].texture.resource_path.ends_with("thunder.svg"),"mind icon matches equipped technique")
	g.passives.clear()
	g._refresh_gear_visual()
	check(g.player.get_node("LoadoutAura").find_children("MindCharm*","Sprite3D",true,false).is_empty(),"unequipping minds removes charms")
	g._cancel_weapon_pose()
	var finished_swing: Tween=g.create_tween()
	g.weapon_tween=finished_swing
	finished_swing.tween_interval(0.01)
	await finished_swing.finished
	g.hit_stop=0.04
	g._sync_weapon_impact()
	g.hit_stop=0
	g._sync_weapon_impact()
	check(not finished_swing.is_running(),"completed swing stays completed after contact pause")
	await process_frame
	await process_frame
	check(not finished_swing.is_valid(),"completed swing is released instead of paused forever")
	if failures.is_empty(): print("COMBAT_FLOW_PASS")
	else: print("COMBAT_FLOW_FAIL ",failures)
	quit(0 if failures.is_empty() else 1)
