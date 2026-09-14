extends RefCounted

const INK=preload("res://assets/models/model_ink.gdshader")
static var shared_ink: ShaderMaterial

const ROOT="res://assets/models/"
const BOSSES=["boss_ferry","boss_wish","boss_judge","boss_erlang","boss_master","boss_debt"]

static func actor(kind: String, chapter: int=1) -> Node3D:
	var id: String=BOSSES[clampi(chapter-1,0,5)] if kind=="boss" else kind
	var scene: PackedScene=load(ROOT+id+".glb")
	var imported: Node3D=scene.instantiate()
	var model: Node3D=imported.get_node(id)
	imported.remove_child(model)
	imported.free()
	apply_ink(model)
	model.set_meta("original_model",id)
	var body: Node3D=model.get_node("Body")
	model.set_meta("rig",{"body":body,"left_arm":body.get_node("LeftArm"),"right_arm":body.get_node("RightArm"),"left_leg":body.get_node("LeftLeg"),"right_leg":body.get_node("RightLeg"),"cloak":body.get_node_or_null("Cloak")})
	return model

static func equip(model: Node3D, id: String) -> void:
	var grip: Node3D=model.find_child("Weapon",true,false)
	for child in grip.get_children(): child.free()
	grip.add_child(weapon(id))

static func robe(model: Node3D, color: Color) -> void:
	var cloth: MeshInstance3D=model.get_node("Body/Cloth")
	var material: ShaderMaterial=shared_ink.duplicate()
	material.set_shader_parameter("cloth_tint",color)
	cloth.material_override=material

static func animate_enemy(model: Node3D, phase: float, mode: String, timer: float) -> void:
	var rig: Dictionary=model.get_meta("rig")
	var body: Node3D=rig["body"]
	var kind: String=model.get_meta("original_model")
	var walking: float=1.0 if mode in ["chase","retreat","charge"] else 0.0
	var stride: float=sin(phase*(0.7 if kind=="brute" else 1.0))
	var step: float=0.32 if kind=="brute" else 0.46
	if mode=="retreat": step=-0.28
	if mode=="charge": step=0.75
	rig["left_leg"].rotation=Vector3(stride*step*walking,0,0)
	rig["right_leg"].rotation=Vector3(-stride*step*walking,0,0)
	var left:=Vector3(-stride*0.16*walking,0,-0.10)
	var right:=Vector3(stride*0.16*walking,0,0.10)
	var twist: float=0.0
	var sway: float=stride*0.025*walking
	var drop: float=absf(stride)*0.025*walking
	var loading: bool=mode in ["tell","charge_tell"]
	var recovering: bool=mode in ["recover","charge_recover"]
	var duration: float=0.9 if kind in ["ranger","brute"] else (1.1 if kind.begins_with("boss_") else 0.6)
	var draw: float=0.22+0.78*smoothstep(0.0,1.0,1.0-clampf(timer/duration,0,1)) if loading else 0.0
	var release: float=sqrt(clampf(timer/(1.05 if mode=="charge_recover" else 0.8),0,1)) if recovering else 0.0
	match kind:
		"grunt":
			right+=Vector3(0.2+0.35*draw+0.95*release,-0.65*draw+0.55*release,0.55*draw)
			left+=Vector3(0.3+0.45*draw,-0.1,-0.15)
			twist=-0.32*draw+0.45*release
		"ranger":
			left=Vector3(0.65+0.65*draw+0.35*release,-0.15,-0.25)
			right=Vector3(0.45+1.25*draw+0.70*release,0.20,-0.08)
			twist=0.20+0.25*draw-0.15*release
			if mode=="retreat":
				left=Vector3(1.25,-0.2,-0.15)
				right=Vector3(0.7,0.15,0.3)
				sway=-0.08
		"brute":
			right=Vector3(0.18+2.2*draw+0.92*release,0,0.12)
			left=Vector3(0.18+1.65*draw+0.90*release,-0.15,-0.2)
			drop=-0.09*draw-0.07*release
			if mode=="charge_tell":
				right=Vector3(0.65,0.15,0.32)
				left=Vector3(1.1,-0.2,-0.35)
				twist=-0.26*draw
				drop=-0.16*draw
			elif mode=="charge":
				right=Vector3(0.9,0.1,0.4)
				left=Vector3(1.4,-0.2,-0.4)
				twist=-0.3
				drop=-0.13
			elif mode=="charge_recover":
				right=Vector3(-0.15,0,0.28)*release
				left=Vector3(-0.05,0,-0.22)*release
				sway=0.10*release
		"boss_ferry":
			right=Vector3(0.35+1.7*draw+0.7*release,-0.35*draw,0.12)
			left=Vector3(0.2+1.1*draw+0.65*release,0,-0.2)
			twist=-0.35*draw+0.55*release
			drop=-0.06*draw
		"boss_wish":
			right=Vector3(0.5+0.65*draw+0.35*release,0.25,0.5+0.65*draw)
			left=Vector3(0.5+0.65*draw+0.35*release,-0.25,-0.5-0.65*draw)
			drop=0.04*draw
		"boss_judge":
			right=Vector3(0.55+1.45*draw+0.5*release,0,0.12)
			left=Vector3(0.85+0.25*draw,-0.25,-0.08)
			twist=-0.15*draw+0.22*release
		"boss_erlang":
			right=Vector3(0.65-0.55*draw+0.85*release,-0.4*draw,0.25)
			left=Vector3(0.6+0.45*draw+0.8*release,0,-0.25)
			twist=-0.40*draw+0.32*release
			if mode=="dash":
				right.x=1.25
				left.x=1.05
				drop=-0.12
		"boss_master":
			right=Vector3(0.35+0.9*draw+1.0*release,-0.4*draw+0.2*release,0.22)
			left=Vector3(0.15+0.1*draw,-0.15,-0.12)
			twist=-0.25*draw+0.2*release
		"boss_debt":
			right=Vector3(0.6+1.3*draw+0.45*release,0.3,0.4*draw)
			left=Vector3(0.25+1.05*draw+0.3*release,-0.3,-0.65*draw)
			sway=-0.10*draw+0.05*release
	rig["left_arm"].rotation=left
	rig["right_arm"].rotation=right
	# The hit-recoil tween owns body.rotation.x.
	body.rotation.y=twist
	body.rotation.z=sway
	body.position.y=drop
	var cloak: Node3D=rig["cloak"]
	if cloak: cloak.rotation.x=sin(phase*0.55)*0.025+walking*0.05

static func animate_player(model: Node3D, dt: float, pose: Dictionary) -> void:
	var rig: Dictionary=model.get_meta("rig")
	var body: Node3D=rig["body"]
	var phase: float=pose["phase"]
	var moving: float=clampf(pose["moving"],0,1)
	var stepping: float=sin(phase)*0.58*moving
	rig["left_leg"].rotation=Vector3(stepping,0,0)
	rig["right_leg"].rotation=Vector3(-stepping,0,0)
	var attack_left: float=pose["attack_left"]
	var fresh_attack: bool=attack_left>float(model.get_meta("last_attack_pose",0.0))+0.0001
	if pose["impact_paused"] and not fresh_attack: return
	model.set_meta("last_attack_pose",attack_left)
	var progress: float=1.0-clampf(attack_left/maxf(0.01,pose["attack_duration"]),0,1)
	var strike: float=sin(lerpf(0.28,1.0,progress)*PI) if attack_left>0 else 0.0
	var hand: float=1.0 if int(pose["combo"])%2==0 else -1.0
	var weight: float=1.0
	var reach: float=1.0
	var left:=Vector3(0.15-sin(phase)*0.15*moving,0,-0.14)
	var right:=Vector3(0.2+sin(phase)*0.12*moving,0,0.12)
	match str(pose["weapon"]):
		"long_sword":
			left=Vector3(0.45,0,-0.2)
			right=Vector3(0.45,0,0.08)
			weight=0.7
		"long_spear":
			left=Vector3(0.7,-0.1,-0.15)
			right=Vector3(0.65,0,0.12)
			reach=1.18
		"iron_staff":
			left=Vector3(0.55,-0.15,-0.24)
			right=Vector3(0.35,0.1,0.35)
			weight=1.1
		"heavy_cleaver":
			left=Vector3(0.35,0,-0.15)
			right=Vector3(0.20,0,0.32)
			weight=1.4
	var twist: float=hand*0.32*strike*weight
	var lean: float=-0.07*moving-strike*0.10*weight
	right.x+=strike*0.85*reach
	left.x+=strike*0.40
	match str(pose["art"]):
		"sweep":
			twist=hand*0.68*strike
			right.z+=hand*0.26*strike
			left.z-=0.36*strike
		"thrust":
			twist=-0.18*strike
			lean-=0.12*strike
			right.x+=0.38*strike
			left.x+=0.22*strike
		"flurry":
			twist=hand*0.22*strike
			left.x+=0.35*strike if hand>0 else 0.0
		"cleave":
			if int(pose["combo"])==3:
				right.x+=0.45*strike*weight
				left.x+=0.3*strike
				lean-=0.08*strike*weight
	var casting: float=sin(lerpf(0.32,1.0,1.0-clampf(pose["cast_left"]/0.24,0,1))*PI) if pose["cast_left"]>0 else 0.0
	left=left.lerp(Vector3(1.45,-0.18,-0.12),casting)
	right=right.lerp(Vector3(0.3,0,0.25),casting*0.7)
	twist=lerpf(twist,-0.18,casting)
	if pose["dashing"]:
		lean=-0.30
		twist=0.0
		left=Vector3(-0.28,0,-0.2)
		right=Vector3(-0.18,0,0.25)
	var blend: float=minf(1,dt*(36.0 if fresh_attack else 24.0))
	rig["left_arm"].rotation=rig["left_arm"].rotation.lerp(left,blend)
	rig["right_arm"].rotation=rig["right_arm"].rotation.lerp(right,blend)
	body.rotation=body.rotation.lerp(Vector3(lean,twist,sin(phase)*0.025*moving),blend)
	var cloak: Node3D=rig["cloak"]
	if cloak: cloak.rotation.x=sin(phase*0.55)*0.025+moving*0.08+(0.13 if pose["dashing"] else 0.0)

static func apply_ink(model: Node3D) -> void:
	if shared_ink==null:
		shared_ink=ShaderMaterial.new()
		shared_ink.shader=INK
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		mesh.material_override=shared_ink

static func weapon(id: String) -> Node3D:
	var scene: PackedScene=load(ROOT+id+".glb")
	var model: Node3D=scene.instantiate()
	apply_ink(model)
	return model
