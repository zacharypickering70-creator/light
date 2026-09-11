extends RefCounted

const INK=preload("res://assets/models/model_ink.gdshader")
static var shared_ink: ShaderMaterial

const ROOT="res://assets/models/"
const BOSSES=["boss_ferry","boss_wish","boss_judge","boss_erlang","boss_master"]

static func actor(kind: String, chapter: int=1) -> Node3D:
	var id: String=BOSSES[clampi(chapter-1,0,4)] if kind=="boss" else kind
	var scene: PackedScene=load(ROOT+id+".glb")
	var imported: Node3D=scene.instantiate()
	var model: Node3D=imported.get_node(id)
	imported.remove_child(model)
	imported.free()
	apply_ink(model)
	model.set_meta("original_model",id)
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
	var body: Node3D=model.get_node("Body")
	var walking: float=1.0 if mode=="chase" else 0.0
	for side in ["Left","Right"]:
		var sign_value: float=1.0 if side=="Left" else -1.0
		body.get_node(side+"Leg").rotation.x=sin(phase)*sign_value*0.45*walking
		body.get_node(side+"Arm").rotation.x=sin(phase)*-sign_value*0.20*walking
	var hand: Node3D=body.get_node("RightArm")
	if mode=="tell": hand.rotation.x=-0.6
	elif mode=="recover": hand.rotation.x=0.7*clampf(timer,0,1)
	var cloak: Node3D=body.get_node_or_null("Cloak")
	if cloak: cloak.rotation.x=sin(phase*0.55)*0.035

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
