extends SceneTree
var failures: Array[String]=[]
func _initialize(): call_deferred("run")
func check(ok: bool, message: String):
	if not ok: failures.append(message)
func run():
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	g.set_process(false)
	g.test_mode=true
	g.music_player.stop()
	g._start_run()
	g.state="playing"
	g.ui.hide_modal()
	g.learned_skills.assign(["fire"])
	g.skill_ranks={"fire":1}
	g.energy=100
	g.skill_cds[0]=0.08
	g._request_skill(0)
	check(g.energy==100 and g.queued_skill==0,"early skill is buffered without spending")
	for i in range(5): g._tick_game(0.02)
	check(g.energy<100 and g.skill_cds[0]>1 and g.queued_skill==-1,"buffer casts once after cooldown")
	var energy: float=g.energy
	var skill_cooldown: float=g.skill_cds[0]
	for i in range(5): g._tick_game(0.02)
	check(g.energy>=energy and g.skill_cds[0]<skill_cooldown,"buffer does not repeat")
	g.dash_cd=0.08
	g._request_dash(Vector3.RIGHT)
	for i in range(5): g._tick_game(0.02)
	check(g.dash_left>0 and g.dash_dir==Vector3.RIGHT,"dash keeps intended direction")
	g.skill_cds[0]=0
	g._request_skill(0)
	check(g.queued_skill==0,"skill waits for dash")
	for i in range(12): g._tick_game(0.02)
	check(g.skill_cds[0]>1,"dash buffered skill resolves")
	g.cast_pose=0
	g.attack_cd=0
	g.dash_left=0
	g._attack()
	var cooldown: float=g.attack_cd
	g.dash_cd=0
	g._dash(Vector3.FORWARD)
	var socket: Node3D=g.player.find_child("Weapon",true,false)
	check(g.attack_cd==cooldown,"cancel cannot bypass attack cooldown")
	check(socket.rotation.is_zero_approx() and socket.position.is_zero_approx(),"dash cleans swing transform")
	g.dash_left=0
	g.skill_cds[0]=0.1
	g._request_skill(0)
	g.state="paused"
	g._process(0.01)
	check(g.queued_skill==-1,"pause clears buffered input")
	g.state="playing"
	g.dash_left=0
	g.skill_cds[0]=0
	g.energy=0
	g.attack_pose=0.1
	g._request_skill(0)
	check(g.attack_pose==0.1 and g.skill_cds[0]==0,"insufficient energy does not cancel or spend cooldown")
	g.energy=100
	g.dash_left=1
	g._request_skill(0)
	for i in range(12): g._tick_combat_buffer(0.02)
	g.dash_left=0
	g._tick_combat_buffer(0.02)
	check(g.skill_cds[0]==0 and g.queued_skill==-1,"expired input never fires late")
	g._start_expedition()
	g.state="playing"
	g._update_hud()
	for pickup in g.pickups:
		if pickup["kind"]=="scroll": check(not g.world._in_ferry_water(pickup["pos"]),"scroll stays on dry shore")
		var glow=pickup["node"].get_node_or_null("DiscoveryGlimmer")
		if glow:
			g.player.position=pickup["pos"]+Vector3(30,0,0)
			g._update_hud()
			check(not glow.visible,"undiscovered hint hidden at distance")
			g.player.position=pickup["pos"]
			g._update_hud()
			check(glow.visible,"nearby discovery hint visible")
			pickup["used"]=true
			g._update_hud()
			check(not glow.visible,"used hint clears")
			break
	if failures.is_empty(): print("COMBAT18_PASS")
	else: print("COMBAT18_FAIL ",failures)
	quit(0 if failures.is_empty() else 1)
