extends SceneTree

const Library=preload("res://scripts/model_library.gd")
var failures: Array[String]=[]
var stage: Node3D
var camera: Camera3D

func _initialize() -> void: call_deferred("run")

func check(value: bool, reason: String) -> void:
	if not value: failures.append(reason)

func pose(weapon: String="ferry_blade", art: String="cleave") -> Dictionary:
	return {"phase":1.0,"moving":0.0,"weapon":weapon,"art":art,"combo":1,"attack_left":0.18,"attack_duration":0.24,"cast_left":0.0,"dashing":false,"impact_paused":false}

func run() -> void:
	var player: Node3D=Library.actor("player")
	root.add_child(player)
	var state: Dictionary=pose()
	state["moving"]=1.0
	Library.animate_player(player,0.05,state)
	var body: Node3D=player.get_node("Body")
	var arm: Node3D=body.get_node("RightArm")
	var body_pose: Vector3=body.rotation
	var arm_pose: Vector3=arm.rotation
	var old_step: float=body.get_node("LeftLeg").rotation.x
	state["impact_paused"]=true
	state["phase"]=2.0
	Library.animate_player(player,0.016,state)
	check(body.rotation.is_equal_approx(body_pose) and arm.rotation.is_equal_approx(arm_pose),"impact holds upper body")
	check(not is_equal_approx(body.get_node("LeftLeg").rotation.x,old_step),"impact allows walk articulation")
	state["impact_paused"]=false
	state["moving"]=0.0
	var socket: Node3D=body.get_node("RightArm/Grip/Weapon")
	var authored_socket: Transform3D=socket.transform
	var weapon_poses: Array[Vector3]=[]
	for id in ["ferry_blade","long_sword","long_spear","iron_staff","heavy_cleaver"]:
		Library.equip(player,id)
		state["weapon"]=id
		Library.animate_player(player,0.1,state)
		weapon_poses.append(arm.rotation)
		check(socket.get_child_count()==1 and socket.transform.is_equal_approx(authored_socket),"weapon socket retained: "+id)
	for i in range(weapon_poses.size()):
		for j in range(i+1,weapon_poses.size()):
			check(weapon_poses[i].distance_to(weapon_poses[j])>0.03,"distinct weapon stance")
	state["weapon"]="long_spear"
	var art_poses: Array[Vector3]=[]
	for art in ["cleave","flurry","thrust","sweep"]:
		state["art"]=art
		Library.animate_player(player,0.1,state)
		art_poses.append(body.rotation)
	for i in range(art_poses.size()):
		for j in range(i+1,art_poses.size()):
			check(art_poses[i].distance_to(art_poses[j])>0.03,"attack art independent of weapon")
	state["attack_left"]=0.0
	state["cast_left"]=0.16
	Library.animate_player(player,0.1,state)
	check(body.get_node("LeftArm").rotation.x>1.0,"casting palm extends forward")
	state["cast_left"]=0.0
	state["dashing"]=true
	Library.animate_player(player,0.1,state)
	check(body.rotation.x<-.25 and arm.rotation.x<0,"dash lowers stance and trails weapon")
	player.free()
	var all_poses: Array[Vector3]=[]
	for kind in ["grunt","ranger","brute"]+Library.BOSSES:
		var enemy: Node3D=Library.actor(kind)
		root.add_child(enemy)
		body=enemy.get_node("Body")
		body.rotation.x=-0.24
		Library.animate_enemy(enemy,0.8,"tell",0.12)
		all_poses.append(body.get_node("RightArm").rotation)
		var loaded: Vector3=body.get_node("RightArm").rotation
		Library.animate_enemy(enemy,0.8,"recover",0.7)
		check(loaded.distance_to(body.get_node("RightArm").rotation)>0.1,"release differs from loading: "+kind)
		for mode in ["chase","retreat","tell","recover","charge_tell","charge","charge_recover"]:
			Library.animate_enemy(enemy,1.0,mode,0.4)
			check(is_equal_approx(body.rotation.x,-0.24),"damage recoil ownership: "+kind+" "+mode)
		check(enemy.find_children("*","MeshInstance3D",true,false).size()<=8,"mesh count unchanged")
		check(body.get_node("Cloth").material_override==Library.shared_ink,"crowd shares ink material")
		enemy.free()
	for i in range(all_poses.size()):
		for j in range(i+1,all_poses.size()):
			check(all_poses[i].distance_to(all_poses[j])>0.04,"enemy tells have distinct silhouettes")
	if "--preview" in OS.get_cmdline_user_args(): await preview()
	if failures.is_empty(): print("ACTOR_MOTION_PASS: five weapons, four independent arts, impact hold, mobile footwork, cast, dash, nine enemy tells, recoil and shared mesh/material budgets")
	else: print("ACTOR_MOTION_FAIL: ",failures)
	quit(0 if failures.is_empty() else 1)

func label_at(copy: String, position: Vector3, size: int=36) -> void:
	var label:=Label3D.new()
	label.text=copy
	label.font=load("res://assets/NotoSansSC.ttf")
	label.font_size=size
	label.pixel_size=0.011
	label.modulate=Color("253c3a")
	label.outline_modulate=Color("eee9d8")
	label.outline_size=6
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test=true
	stage.add_child(label)
	label.position=position

func capture(file: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/"+file+".png")
	for child in stage.get_children(): child.free()

func preview() -> void:
	root.size=Vector2i(1440,900)
	var scene:=Node3D.new()
	root.add_child(scene)
	stage=Node3D.new()
	scene.add_child(stage)
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("e1ddcb")
	scene.add_child(env)
	camera=Camera3D.new()
	scene.add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=18
	camera.position=Vector3(0,15,-24)
	camera.look_at(Vector3(0,0.8,0))
	camera.current=true
	var floor_mesh:=MeshInstance3D.new()
	floor_mesh.mesh=PlaneMesh.new()
	floor_mesh.mesh.size=Vector2(60,60)
	var mat:=StandardMaterial3D.new()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=Color("d8d4c2")
	floor_mesh.material_override=mat
	floor_mesh.position.y=-0.025
	scene.add_child(floor_mesh)
	for row in range(3):
		for col in range(3):
			var kind: String=["grunt","ranger","brute"][col]
			var mode: String=["chase","tell","recover"][row]
			var actor: Node3D=Library.actor(kind)
			stage.add_child(actor)
			actor.position=Vector3((col-1)*6.1,0,(1-row)*5.1)
			actor.rotation.y=-0.28
			Library.animate_enemy(actor,0.8,mode,0.12 if mode=="tell" else 0.65)
			label_at(["符面刀客","青衣咒师","负甲重卒"][col]+" · "+["追击","蓄势","收招"][row],actor.position+Vector3(0,2.9,0),29)
	await capture("动作精修-小怪读招")
	camera.size=12
	for i in range(3):
		var actor: Node3D=Library.actor("brute")
		stage.add_child(actor)
		actor.position=Vector3((i-1)*5.0,0,0)
		actor.scale*=1.4
		actor.rotation.y=-0.5
		Library.animate_enemy(actor,0.8,["charge_tell","charge","charge_recover"][i],0.18 if i==0 else 0.85)
		label_at(["沉肩蓄势","直线冲压","力竭破绽"][i],actor.position+Vector3(0,4,0),34)
	await capture("动作精修-重卒冲压")
	camera.size=18
	for i in range(6):
		var actor: Node3D=Library.actor("boss",i+1)
		stage.add_child(actor)
		actor.position=Vector3((i%3-1)*6.3,0,(0.5-floorf(i/3.0))*7.8)
		actor.rotation.y=-0.23
		Library.animate_enemy(actor,0.8,"tell",0.12)
		label_at(["缚舟 · 提桨","百愿娘娘 · 展袖","无名判影 · 举牍","二郎神 · 蓄刺","陆照川 · 运笔","百契债身 · 称债"][i],actor.position+Vector3(0,4.6,0),30)
	await capture("动作精修-六章首领")
	camera.size=14
	for i in range(5):
		var actor: Node3D=Library.actor("player")
		stage.add_child(actor)
		actor.position=Vector3((i-2)*3.6,0,0)
		actor.scale*=1.5
		actor.rotation.y=-0.35
		var id: String=["ferry_blade","long_sword","long_spear","iron_staff","heavy_cleaver"][i]
		Library.equip(actor,id)
		Library.animate_player(actor,0.1,pose(id))
		label_at(["朴刀","青锋剑","红缨枪","盘龙棍","开山斧"][i],actor.position+Vector3(0,3.8,0),34)
	label_at("同一套路 · 五种持械姿态",Vector3(0,5,3),40)
	await capture("动作精修-五种持械")
	for i in range(6):
		var actor: Node3D=Library.actor("player")
		stage.add_child(actor)
		actor.position=Vector3((i%3-1)*5.2,0,(0.5-floorf(i/3.0))*5.8)
		actor.scale*=1.2
		actor.rotation.y=-0.35
		var state: Dictionary=pose("ferry_blade",["cleave","flurry","thrust","sweep","cleave","cleave"][i])
		if i==4: state["cast_left"]=0.16
		if i==5: state["dashing"]=true
		Library.animate_player(actor,0.1,state)
		label_at(["断岳横斩","流星快打","长虹贯日","八方扫叶","伸掌施法","踏影收身"][i],actor.position+Vector3(0,3.3,0),30)
	await capture("动作精修-套路与衔接")
