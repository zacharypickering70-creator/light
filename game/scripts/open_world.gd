extends "res://scripts/world_art.gd"

const INK_SHADER = preload("res://assets/ink.gdshader")
const GROUND_SHADER = preload("res://assets/paper_ground.gdshader")
const LANDMARK_NAMES = ["落灯坪", "风竹林", "听雨亭", "无声渡", "枯荷汀", "归墨碑", "镇渡台"]
var chapter: int=1
var final_scene: Node3D
const SHRINE_NAMES=["祈愿门","香客林","解签亭","万愿廊","醒梦池","无字碑","听愿正殿"]
var landmarks: Array[Dictionary] = []
var obstacles: Array[Dictionary] = []
var map_seed: int = 0
var map_radius: float = 54.0
var boss_place_title: Label3D
var river_souls: Dictionary={}
var worshippers: Array[Dictionary] = []

func populate_worshippers() -> void:
	worshippers.clear()
	if chapter!=2: return
	for group in [0,2,4,6]:
		var center: Vector3=landmarks[group]["pos"]
		var count: int=16 if group==6 else (6 if group==0 else 8)
		for i in range(count):
			var person:=Node3D.new()
			person.name="求愿者_%d_%d"%[group,i]
			_room.add_child(person)
			# Two side banks leave the center of the shrine approach open.
			var side: float=-1.0 if i%2==0 else 1.0
			person.position=center+Vector3(side*(3.0+float((i/2)%2)*1.5),0,3.0+float(i/4)*1.6)
			var robe: Color=[Color("696d60"),Color("8c8066"),Color("626e72"),Color("8d776a")][i%4]
			_cylinder(person,Vector3(0,0.025,0),0.52,0.52,0.035,Color("9c8964"),10)
			_box(person,Vector3(0,0.17,0.23),Vector3(0.48,0.28,0.57),robe)
			var bow:=Node3D.new()
			person.add_child(bow)
			bow.position.y=0.38
			_cylinder(bow,Vector3(0,0.27,0),0.20,0.28,0.55,robe,7)
			_sphere(bow,Vector3(0,0.70,-0.03),0.18,Color("b6a78c"),8)
			for hand in [-1.0,1.0]:
				_beam(bow,Vector3(hand*0.22,0.40,0),Vector3(hand*0.14,0.62,-0.10),0.075,robe)
				_sphere(bow,Vector3(hand*0.14,0.62,-0.10),0.065,Color("b6a78c"),6)
			for mesh in bow.get_children():
				if mesh is GeometryInstance3D: mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			worshippers.append({"node":person,"bow":bow,"group":group,"phase":_rng.randf()*TAU,"pace":_rng.randf_range(0.8,1.2),"awake":false,"time":0.0})

func tick_worshippers(dt: float) -> void:
	for person in worshippers:
		if not is_instance_valid(person["node"]): continue
		var node: Node3D=person["node"]
		var bow: Node3D=person["bow"]
		person["time"]+=dt
		if person["awake"]:
			var t: float=person["time"]
			bow.rotation.x=lerpf(float(person["start_bow"]),0,minf(t,1))
			bow.position.y=lerpf(float(person["start_height"]),0.75,minf(t,1))
			if t>1:
				node.position+=person["exit_dir"]*dt*1.6
				bow.rotation.z=sin(t*7)*0.035
			if t>5: node.scale=Vector3.ONE*maxf(0.0,1-(t-5)/1.5)
			if t>6.5: node.visible=false
		else:
			var cycle: float=(sin(float(person["time"])*1.3*float(person["pace"])+float(person["phase"]))+1)*0.5
			bow.rotation.x=-1.35*pow(cycle,0.7)
			bow.position.y=0.38-0.30*cycle

func wake_worshippers(group: int) -> void:
	for person in worshippers:
		if not is_instance_valid(person["node"]) or person["awake"]: continue
		if group>=0 and person["group"]!=group: continue
		person["awake"]=true
		person["time"]=0.0
		person["start_bow"]=person["bow"].rotation.x
		person["start_height"]=person["bow"].position.y
		var node: Node3D=person["node"]
		person["exit_dir"]=(Vector3.ZERO-node.position).normalized() if node.position.length()>2 else Vector3(0,0,1)
		node.rotation.y=atan2(-person["exit_dir"].x,-person["exit_dir"].z)

func generate_layout(value: int) -> Array[Dictionary]:
	var random := RandomNumberGenerator.new()
	random.seed = value
	var points: Array[Vector3] = [Vector3.ZERO]
	var tries: int = 0
	while points.size() < 7 and tries < 2000:
		tries += 1
		var angle: float = random.randf_range(0, TAU)
		var radius: float = sqrt(random.randf()) * 44
		var point := Vector3(sin(angle)*radius, 0, cos(angle)*radius)
		var valid: bool = radius > 20
		for other in points:
			if point.distance_to(other) < 19: valid = false
		if valid: points.append(point)
	# A deterministic fallback also guarantees seven reachable landmarks for rare seeds.
	if points.size() < 7:
		points = [Vector3.ZERO]
		for i in range(6):
			var angle: float = TAU * i / 6.0 + random.randf()
			points.append(Vector3(sin(angle)*37, 0, cos(angle)*37))
	var farthest: int = 1
	for i in range(1, points.size()):
		if points[i].length() > points[farthest].length(): farthest = i
	var temp: Vector3 = points[6]
	points[6] = points[farthest]
	points[farthest] = temp
	var result: Array[Dictionary] = []
	for i in range(7):
		var names: Array=preload("res://scripts/chapter_three.gd").NAMES if chapter==3 else (SHRINE_NAMES if chapter==2 else LANDMARK_NAMES)
		if chapter==6: names=preload("res://scripts/chapter_six.gd").NAMES
		if chapter==5: names=preload("res://scripts/chapter_five.gd").NAMES
		if chapter==4: names=preload("res://scripts/chapter_four.gd").NAMES
		result.append({"id":i, "name":names[i], "pos":points[i], "visited":i==0})
	return result

func build_map(value: int, preview: bool = false) -> void:
	boss_place_title=null
	river_souls.clear()
	worshippers.clear()
	map_radius=20.0 if preview else 54.0
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_ember_nodes.clear()
	obstacles.clear()
	_materials.clear()
	map_seed = value
	_rng.seed = value
	landmarks.assign([{"id":0,"name":"竹隐居","pos":Vector3.ZERO,"visited":true}] if preview else generate_layout(value))
	_room = Node3D.new()
	add_child(_room)
	var root_art: Node3D = _room
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("e7e2d4")
	if chapter==3 and not preview: env.background_color=Color("cbd8d5")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f5f0e3")
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = Color("e7e2d4")
	if chapter==3 and not preview: env.fog_light_color=Color("b5cccb")
	env.fog_light_energy = 1.0
	env.fog_density = 0.0015
	environment.environment = env
	root_art.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-30,0)
	sun.light_color = Color("fff5df")
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 40
	root_art.add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(160,160)
	ground.mesh = plane
	var paper := ShaderMaterial.new()
	paper.shader = GROUND_SHADER
	ground.material_override = paper
	ground.position.y = -0.055
	root_art.add_child(ground)
	if preview:
		_home_courtyard()
		for i in range(90):
			var a: float=i*TAU/90
			var radius: float=_rng.randf_range(12.0,25.0)
			_bamboo(Vector3(cos(a)*radius,0,sin(a)*radius))
		for i in range(12):
			var p:=Vector3(_rng.randf_range(-10,10),0,_rng.randf_range(7,11))
			_box(_room,p,Vector3(0.7,0.04,0.4),Color("b4b6a2"))
		_box(_room,Vector3(3,0.65,1),Vector3(1.8,0.18,1.1),Color("736343"))
		for i in range(3):
			_box(_room,Vector3(2.5+i*0.5,0.8,1),Vector3(0.3,0.1,0.55),Color("c2b995"))
		var dummy: Node3D=create_actor("dummy")
		_room.add_child(dummy)
		dummy.position=Vector3(0,0,-3)
		for i in range(3): _torus(_room,Vector3(8,0.08+i*0.05,4),1.5+i*0.3,1.55+i*0.3,Color("aab99a"))
		for i in range(6):
			var a: float=i*TAU/6
			_cylinder(_room,Vector3(8+cos(a)*2,0.2,4+sin(a)*2),0.12,0.25,0.4,Color("ada483"),6)
		_ground_dressing(true)
		return
	for landmark in landmarks:
		var region := Node3D.new()
		region.position = landmark["pos"]
		root_art.add_child(region)
		_room = region
		var id: int = landmark["id"]
		if chapter==6:
			_city_region(id)
		elif chapter==5:
			_final_region(id)
		elif chapter==4:
			_mountain_region(id)
		elif chapter==3:
			_river_region(id)
		elif chapter==2:
			_shrine_region(id)
		elif id == 0:
			_torus(_room,Vector3.ZERO,2.5,2.6,Color("84977a"))
			_lantern(Vector3(2.8,0,-2.7),0.9,Color("a84936"),false)
		elif id == 6:
			# The boss clearing can be approached from every direction.
			_cylinder(_room,Vector3(0,0.005,0),8,8,0.08,Color("a19d91"),64)
			_torus(_room,Vector3(0,0.06,0),7.6,7.7,Color("3c3b37"))
			_gate(Vector3(0,0,-10),6,1.25,Color("ad4938"))
			_banner(Vector3(-7,0,-7),-1,Color("a44034"))
			_banner(Vector3(7,0,-7),1,Color("a44034"))
		elif id == 1:
			for j in range(16):
				_bamboo(Vector3(-9+(j%4)*1.4,0,-6+(j/4)*2.0))
		elif id == 2:
			_pavilion(Vector3(-6,0,-4),1)
		elif id == 3:
			_gate(Vector3(-5,0,-7),4.4,0.85,Color("a64c3a"))
			_boat(Vector3(7,0,-5))
			_dock_details()
		elif id == 4:
			_pond_details()
		elif id == 5:
			_box(_room,Vector3(-4,1.7,-5),Vector3(1.8,3.4,0.8),Color("64645b"))
			_box(_room,Vector3(-4,3.5,-5),Vector3(2.5,0.22,1.25),Color("292d2b"))
		_region_details(id)
		if chapter==1: preload("res://scripts/ferry_art.gd").dress(self,id)
		for side in [-1.0,1.0]:
			var tree_pos := Vector3(side*9,0,-7)
			if chapter==1 and ((id==3 and side>0) or (id==4 and side<0)):
				tree_pos=Vector3(side*14,0,-10)
			_tree(tree_pos,side,0.9)
		if id != 0 and id != 6:
			_lantern(Vector3(5,0,4),0.8,Color("a74432"),false)
		var title := Label3D.new()
		title.text = landmark["name"]
		title.name = "LandmarkTitle"
		if id==6: boss_place_title=title
		title.font_size = 52
		title.pixel_size = 0.018
		title.modulate = Color("fff3d5")
		title.outline_modulate = Color("202924")
		title.outline_size = 10
		title.shaded = false
		title.no_depth_test = true
		title.visibility_range_end = 38
		title.visibility_range_end_margin = 2
		title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		if ResourceLoader.exists("res://assets/NotoSansSC.ttf"): title.font = load("res://assets/NotoSansSC.ttf")
		_room.add_child(title)
		title.position = Vector3(0,4.5,-5.3)
		preload("res://scripts/world_label.gd").finish(title)
	_room = root_art
	for i in range(95):
		var p := Vector3(_rng.randf_range(-54,54),0,_rng.randf_range(-54,54))
		if p.length() > 55 or _near_landmark(p,10) or _in_ferry_water(p): continue
		if i % 3 == 0:
			_tree(p, 1.0 if i%2==0 else -1.0,_rng.randf_range(0.55,1.05))
			obstacles.append({"pos":p,"radius":0.6})
		elif i % 3 == 1:
			_rock(p,_rng.randf_range(0.45,1.0))
			obstacles.append({"pos":p,"radius":0.7})
		else:
			_bamboo(p)
	_ground_dressing(false)
	# Distant mountains blend into the paper background without partitioning the land.
	for i in range(30):
		var angle: float = i*TAU/30
		var h: float = _rng.randf_range(8,20)
		var p := Vector3(sin(angle)*74,h*0.32-3,cos(angle)*74)
		_cylinder(root_art,p,0.5,_rng.randf_range(6,10),h,Color("b3b2a9"),5)
	if preview:
		landmarks[0]["visited"] = true

func _near_landmark(p: Vector3, radius: float) -> bool:
	for landmark in landmarks:
		if p.distance_to(landmark["pos"]) < radius: return true
	return false

func _boat(pos: Vector3) -> void:
	preload("res://scripts/ferry_art.gd").boat(self,pos)

func _bamboo(pos: Vector3) -> void:
	var height: float=_rng.randf_range(4.6,6.2)
	var stalk:=Node3D.new()
	_room.add_child(stalk)
	stalk.position=pos
	stalk.rotation.z=_rng.randf_range(-0.06,0.06)
	_cylinder(stalk,Vector3(0,height*0.5,0),0.055,0.085,height,Color("546d4f"),6)
	for i in range(7):
		_cylinder(stalk,Vector3(0,0.4+i*height/7,0),0.089,0.089,0.045,Color("a0ab86"),6)
	var leaves:=SurfaceTool.new()
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(4):
		var a: float=_rng.randf_range(0,TAU)
		var base:=Vector3(0,height*(0.46+j*0.14),0)
		var tip: Vector3=base+Vector3(cos(a)*0.8,0.18,sin(a)*0.8)
		_beam(stalk,base,tip,0.024,Color("687d55"))
		for k in range(7):
			var la: float=a+(k-3)*0.43
			var start: Vector3=base.lerp(tip,0.4+0.08*k)
			var end: Vector3=start+Vector3(cos(la)*1.0,_rng.randf_range(-0.4,0.25),sin(la)*1.0)
			var side:=Vector3(-sin(la),0,cos(la))*0.11
			var middle: Vector3=start.lerp(end,0.4)+Vector3.UP*0.07
			for point in [start,middle+side,end,start,end,middle-side]: leaves.add_vertex(point)
	leaves.generate_normals()
	var mesh:=MeshInstance3D.new()
	mesh.mesh=leaves.commit()
	var leaf_material:=StandardMaterial3D.new()
	leaf_material.albedo_color=Color("52694f").lightened(_rng.randf_range(0,0.08))
	leaf_material.roughness=1.0
	leaf_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh.material_override=leaf_material
	stalk.add_child(mesh)
	_batch_static(stalk)

func constrain_position(pos: Vector3) -> Vector3:
	var flat := Vector2(pos.x,pos.z).limit_length(map_radius)
	var result := Vector3(flat.x,pos.y,flat.y)
	for obstacle in obstacles:
		var away: Vector3 = result-obstacle["pos"]
		away.y = 0
		var radius: float = obstacle["radius"]+0.4
		if away.length() < radius:
			if away.length() < 0.01: away = Vector3.RIGHT
			result = obstacle["pos"]+away.normalized()*radius
			result.y=pos.y
	return result

func region_at(pos: Vector3) -> int:
	var nearest: int = 0
	var distance: float = INF
	for item in landmarks:
		var d: float = pos.distance_to(item["pos"])
		if d<distance:
			distance=d
			nearest=item["id"]
	return nearest

func _material(color: Color, emission: float = 0.0, double_sided: bool = false) -> Material:
	var red: bool = color.r > color.g*1.45 and color.r>0.25
	var gray: float = color.r*0.28+color.g*0.55+color.b*0.17
	var ink: Color = Color(gray*0.88,gray*0.88,gray*0.82) if not red else Color("994334")
	if color.g>color.r*1.1 and color.g>color.b*1.08: ink=Color(gray*0.74,gray*0.98,gray*0.72)
	if chapter==3 and color.b>color.r*1.12: ink=Color(gray*0.65,gray*0.94,gray*1.1)
	if emission>0:
		ink=Color("c08050") if red or color.r>0.6 else Color("9c9b82")
	var key: String = ink.to_html()+str(double_sided)
	if _materials.has(key): return _materials[key]
	var material := ShaderMaterial.new()
	material.shader=INK_SHADER
	material.set_shader_parameter("ink_color",ink)
	_materials[key]=material
	return material


func _home_courtyard() -> void:
	# A sheltered courtyard with open approaches, workbench, tea table and weapon rack.
	_box(_room,Vector3(-4,0.12,-6),Vector3(8,0.24,5),Color("aaa496"))
	_box(_room,Vector3(-4,1.65,-8),Vector3(7.2,3.1,0.22),Color("c8c2b0"))
	for side in [-1.0,1.0]:
		_box(_room,Vector3(-4+side*3.5,1.65,-6.4),Vector3(0.22,3.1,3.2),Color("c8c2b0"))
		_cylinder(_room,Vector3(-4+side*3.5,1.6,-4.5),0.12,0.15,3,Color("4b4237"),8)
	_roof(_room,Vector3(-4,3.3,-6.2),4.2,2.7,Color("343d36"))
	for x in [-6.2,-2.0]:
		_box(_room,Vector3(x,1.85,-7.84),Vector3(1.3,1.4,0.05),Color("927c51"))
		for k in range(4):
			_box(_room,Vector3(x-0.55+k*0.36,1.85,-7.77),Vector3(0.05,1.4,0.06),Color("413c31"))
		for k in range(3): _box(_room,Vector3(x,1.35+k*0.5,-7.74),Vector3(1.35,0.045,0.05),Color("413c31"))
	_box(_room,Vector3(-4,0.7,-5),Vector3(1.6,0.15,0.85),Color("67503a"))
	for x in [-4.6,-3.4]: _box(_room,Vector3(x,0.35,-5),Vector3(0.1,0.7,0.7),Color("67503a"))
	_cylinder(_room,Vector3(-4.2,0.85,-5),0.13,0.12,0.17,Color("d3c7a8"),10)
	_box(_room,Vector3(-5.3,0.35,-4.4),Vector3(0.8,0.15,0.6),Color("766047"))
	for j in range(10):
		var p:=Vector3(-7.5+(j%5)*1.6,0.025,-2.5+(j/5)*1.4)
		_box(_room,p,Vector3(1.4,0.04,1.15),Color("bab4a5").darkened((j%3)*0.03))
	for x in [-4.0,-2.0]: _beam(_room,Vector3(x,0,0),Vector3(x,1.6,0),0.08,Color("67503a"))
	_beam(_room,Vector3(-4.2,1.3,0),Vector3(-1.8,1.3,0),0.08,Color("67503a"))
	for i in range(4):
		_beam(_room,Vector3(-3.8+i*0.5,0.1,-0.2),Vector3(-3.6+i*0.5,2.1,-0.15),0.035,Color("b9b9a7"))
		_box(_room,Vector3(-3.6+i*0.5,2.1,-0.15),Vector3(0.17,0.4,0.08),Color("c9cbbb"))
	for x in [-7.7,0.2]: _lantern_small(_room,Vector3(x,2.35,-4.5),Color("d98d52"),1.2)
	_cylinder(_room,Vector3(2.8,0.65,-2.5),0.65,0.5,1.2,Color("494941"),10)
	_cylinder(_room,Vector3(2.8,1.26,-2.5),0.46,0.46,0.04,Color("df8a43"),12,0.8)
	var smoke:=Sprite3D.new()
	smoke.texture=load("res://assets/kenney/smoke_01.png")
	smoke.pixel_size=0.005
	smoke.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	smoke.modulate=Color(0.4,0.4,0.36,0.24)
	smoke.position=Vector3(2.8,2.25,-2.5)
	_room.add_child(smoke)
	_ember_nodes.append(smoke)
	smoke.set_meta("base_y",2.25)
	for i in range(4): _rock(Vector3(5.5+i*0.7,0,-5),0.4)
	obstacles.append({"pos":Vector3(-4,0,-6.9),"radius":1.2})

func _dock_details() -> void:
	preload("res://scripts/ferry_art.gd").water(self,Vector3(8,0.015,-5),4.3,4.8)
	for j in range(12):
		_box(_room,Vector3(3.5,0.16,-8+j*0.55),Vector3(3.8,0.12,0.48),Color("797564").darkened((j%3)*0.04))
	for j in range(4):
		_cylinder(_room,Vector3(1.9,0.6,-8+j*2),0.12,0.16,1.2,Color("575748"),8)
	for i in range(5):
		var ripple:=_torus(_room,Vector3(7+(i%2)*2,0.07,-8+i*1.2),0.6,0.62,Color("b7beb0"))
		ripple.scale.z=0.5
	for i in range(3): _box(_room,Vector3(-1+i*1.0,0.4,-6),Vector3(0.85,0.8,0.85),Color("6d6955"))

func _pond_details() -> void:
	preload("res://scripts/ferry_art.gd").water(self,Vector3(-6,0.015,-5),4.5,4.3)
	for i in range(12):
		var a: float=i*TAU/12
		_rock(Vector3(-6+cos(a)*4.5,0,-5+sin(a)*4.5),0.45)
	for i in range(9):
		var p:=Vector3(-8+(i%3)*1.5,0.10,-7+(i/3)*1.7)
		_cylinder(_room,p,0.45,0.45,0.035,Color("718573"),8)
		_beam(_room,p,p+Vector3(0.1,0.65,0),0.025,Color("656e54"))
		_cylinder(_room,p+Vector3(0.1,0.7,0),0.08,0.20,0.14,Color("b2a187"),6)

func _region_details(id: int) -> void:
	for j in range(7):
		var p:=Vector3(_rng.randf_range(-8,8),0.03,_rng.randf_range(4,8))
		var stone:=_box(_room,p,Vector3(_rng.randf_range(0.3,0.8),0.06,_rng.randf_range(0.4,1.1)),Color("b1afa1"))
		stone.rotation.y=_rng.randf_range(0,PI)
	if id==2:
		_box(_room,Vector3(-5,0.6,-4),Vector3(1.5,0.15,1.2),Color("6c6b59"))
		_cylinder(_room,Vector3(-5,0.75,-4),0.22,0.16,0.2,Color("b8b7a4"),8)
	if id==5:
		for j in range(6):
			_box(_room,Vector3(-4,2.7-j*0.3,-4.57),Vector3(0.6+(j%2)*0.3,0.04,0.02),Color("343d36"))
		_lantern_small(_room,Vector3(-2.3,1.1,-4.7),Color("e09b68"),0.8)

func _shrine_region(id: int) -> void:
	_cylinder(_room,Vector3(0,0.01,0),7,7,0.08,Color("b8af97"),40)
	_gate(Vector3(0,0,-7),5.5,1.0,Color("984d42"))
	for side in [-1,1]:
		_lantern(Vector3(side*5,0,-2),1.1,Color("c87945"),false)
		_banner(Vector3(side*6,0,4),side,Color("a75d4c"))
	if id==6:
		_pavilion(Vector3(0,0,-4),1.5)
		_cylinder(_room,Vector3(0,0.3,-3),1.8,2.2,0.6,Color("756c59"),16)
		_cylinder(_room,Vector3(0,1.6,-3),0.6,1.0,2.1,Color("8e8270"),10)
		_sphere(_room,Vector3(0,2.95,-3),0.45,Color("b4a27b"),12)
		_torus(_room,Vector3(0,2.5,-2.7),1.0,1.08,Color("c6a663"),Vector3(PI/2,0,0))
	elif id in [2,4]:
		_pavilion(Vector3(-4,0,-3),0.9)
	else:
		for i in range(4):
			_box(_room,Vector3(-3+i*2,1.0,-3),Vector3(0.35,2,0.3),Color("695b47"))
			_box(_room,Vector3(-3+i*2,1.65,-2.75),Vector3(0.55,0.65,0.035),Color("d5c497"))

func _river_region(id: int) -> void:
	_cylinder(_room,Vector3(0,0.015,0),8,8,0.07,Color("8daba8"),40)
	for side in [-1,1]:
		_box(_room,Vector3(side*6,0.02,0),Vector3(2.6,0.035,15),Color("5f858d"))
		for i in range(4):
			_lantern_small(_room,Vector3(side*6,0.3,-5+i*3),Color("9dd7cc"),0.65)
	if id==6:
		_cylinder(_room,Vector3(0,0.07,0),4.8,4.8,0.12,Color("4e6669"),24)
		_torus(_room,Vector3(0,0.16,0),4.5,4.62,Color("bdd5cb"),Vector3.ZERO)
		for i in range(8):
			var a: float=i*TAU/8
			var p:=Vector3(cos(a)*5,1.3,sin(a)*5)
			_box(_room,p,Vector3(0.58,2.6,0.35),Color("c2c4af"))
			_box(_room,p+Vector3(0,0,-0.2),Vector3(0.09,1.6,0.04),Color("354e51"))
	elif id==1:
		_pavilion(Vector3(0,0,-4),1.0)
		_box(_room,Vector3(0,0.8,-2),Vector3(3,0.16,1.2),Color("526664"))
		for i in range(4): _cylinder(_room,Vector3(-1+i*0.65,0.98,-2),0.16,0.1,0.18,Color("c8c6ab"),10)
		_river_person(Vector3(0,0,-3.2),Color("7c8b80"),false)
	elif id in [2,4]:
		_boat(Vector3(3,0,-3))
		river_souls[id]=_river_person(Vector3(-3,0,3),Color("a1b5af"),false)
		for i in range(3): _box(_room,Vector3(-2+i*1.5,0.3,-2),Vector3(0.9,0.6,0.7),Color("6d7d78"))
	elif id in [3,5]:
		for i in range(5):
			_box(_room,Vector3(-3+i*1.5,1.2,-3),Vector3(0.55,2.4,0.3),Color("aebdb7"))
			for j in range(3): _box(_room,Vector3(-3+i*1.5,1.7-j*0.4,-2.82),Vector3(0.35,0.07,0.03),Color("3f6269"))
		if id==3: _river_person(Vector3(2,0,1),Color("4b6269"),true)
	else:
		_gate(Vector3(0,0,-5),5,1.0,Color("7ca9a9"))
		_boat(Vector3(4,0,-2))

func _river_person(pos: Vector3, cloth: Color, judge: bool) -> Node3D:
	var person:=Node3D.new()
	_room.add_child(person)
	person.position=pos
	_cylinder(person,Vector3(0,0.65,0),0.24,0.4,1.3,cloth,9)
	_sphere(person,Vector3(0,1.5,0),0.23,Color("c3c3ad"),10)
	_cylinder(person,Vector3(0,1.74,0),0.28,0.29,0.2 if judge else 0.08,cloth,8)
	_box(person,Vector3(0,0.95,-0.32),Vector3(0.65,0.4,0.09),Color("d4ccb1"))
	return person

func release_river_soul(id: int) -> void:
	var soul: Node3D=river_souls.get(id)
	if not is_instance_valid(soul): return
	river_souls.erase(id)
	var departure:=create_tween()
	departure.tween_property(soul,"position",soul.position+Vector3(4,0,-3),2.5)
	departure.tween_property(soul,"scale",Vector3.ONE*0.02,0.8)
	departure.tween_callback(soul.queue_free)

func _mountain_region(id: int) -> void:
	_cylinder(_room,Vector3(0,0.02,0),8,8,0.08,Color("bfc6bd"),40)
	for side in [-1,1]:
		_cylinder(_room,Vector3(side*9,3.5,-6),0.15,2.5,7,Color("667c75"),5)
		_cylinder(_room,Vector3(side*9,7.3,-6),0,1.2,2.6,Color("d9ded4"),5)
		_tree(Vector3(side*7,0,5),side,1.1)
		_banner(Vector3(side*5.8,0,2),side,Color("a4b1ab"))
	if id==6:
		_cylinder(_room,Vector3(0,0.08,0),5.4,5.4,0.15,Color("566963"),32)
		_torus(_room,Vector3(0,0.19,0),4.8,4.9,Color("d3c69d"),Vector3.ZERO)
		for i in range(8):
			var a: float=i*TAU/8
			var p:=Vector3(cos(a)*6,1.25,sin(a)*6)
			_box(_room,p,Vector3(0.7,2.5,0.7),Color("bcc6bd"))
			_sphere(_room,p+Vector3.UP*1.45,0.18,Color("d8cb9d"),8)
	elif id in [2,4]:
		_pavilion(Vector3(0,0,-4),0.9)
		_torus(_room,Vector3(-3,0.08,3),1.4,1.5,Color("bba677"),Vector3.ZERO)
		_lantern_small(_room,Vector3(-3,1.5,3),Color("d9c88f"),1.0)
	elif id in [3,5]:
		_box(_room,Vector3(0,1.8,-3),Vector3(1.6,3.6,0.65),Color("809088"))
		for i in range(6): _box(_room,Vector3(0,2.8-i*0.4,-2.65),Vector3(0.8,0.1,0.03),Color("d8d6bd"))
	else:
		_gate(Vector3(0,0,-5),5.5,1.1,Color("a2a38f"))
		for i in range(3): _box(_room,Vector3(0,0.07,-2+i*1.3),Vector3(4,0.14,0.8),Color("c4c9bd"))

func _final_region(id: int) -> void:
	_cylinder(_room,Vector3(0,0.025,0),8,8,0.08,Color("cbbd9d"),40)
	for i in range(8):
		var a: float=i*TAU/8
		var p:=Vector3(cos(a)*6.8,0,sin(a)*6.8)
		_lantern_small(_room,p+Vector3.UP*1.6,Color("e1ba70"),0.9)
	if id==6:
		_cylinder(_room,Vector3(0,0.09,0),5.6,5.6,0.15,Color("765f59"),40)
		for i in range(8):
			var a: float=i*TAU/8
			var petal:=_sphere(_room,Vector3(cos(a)*3.7,0.13,sin(a)*3.7),1.2,Color("b99784"),12)
			petal.scale=Vector3(1,0.10,1.8)
			petal.rotation.y=-a+PI/2
		_torus(_room,Vector3(0,0.21,0),4.9,5.0,Color("e1c27d"),Vector3.ZERO)
	elif id in [1,2,4]:
		_pavilion(Vector3(0,0,-4),0.85)
		var person:=Node3D.new()
		_room.add_child(person)
		person.position=Vector3(-3,0,3)
		_cylinder(person,Vector3(0,0.55,0),0.25,0.4,1.1,Color("7a8274"),8)
		_sphere(person,Vector3(0,1.28,0),0.22,Color("c8b89a"),8)
	elif id in [3,5]:
		_box(_room,Vector3(0,1.2,-3),Vector3(2.2,2.4,0.6),Color("8b8b76"))
		for i in range(5): _box(_room,Vector3(0,2.0-i*0.35,-2.68),Vector3(1.2,0.08,0.03),Color("e0cda5"))
	else:
		_gate(Vector3(0,0,-5),6,1.2,Color("9e705a"))
		for side in [-1,1]: _tree(Vector3(side*6,0,3),side,1.0)

func show_final_phase(phase: int, center: Vector3) -> void:
	if is_instance_valid(final_scene): final_scene.queue_free()
	final_scene=Node3D.new()
	add_child(final_scene)
	final_scene.position=center
	final_scene.position.y=0
	var saved_room: Node3D=_room
	_room=final_scene
	if phase==1:
		for side in [-1,1]:
			_box(_room,Vector3(side*9,0.08,0),Vector3(1.0,0.05,12),Color("8a5549"))
	elif phase==2:
		for i in range(6):
			var a: float=i*TAU/6
			var p:=Vector3(cos(a)*9,0,sin(a)*9)
			_cylinder(_room,p+Vector3.UP*0.7,0.25,0.45,1.4,Color("919d94"),8)
			_sphere(_room,p+Vector3.UP*1.6,0.23,Color("c0c5b2"),8)
			_lantern_small(_room,p+Vector3(0.5,1,0),Color("b3d0c0"),0.6)
	else:
		_box(_room,Vector3(0,0.05,0),Vector3(17,0.05,17),Color("b8b396"))
		_gate(Vector3(0,0,-9),6,1.1,Color("787d62"))
		_pavilion(Vector3(-10,0,-5),0.9)
		for side in [-1,1]:
			for i in range(4): _tree(Vector3(side*10,0,i*4-3),side,1.1)
	_room=saved_room

func _city_region(id: int) -> void:
	_cylinder(_room,Vector3(0,0.025,0),8,8,0.06,Color("aeb4a0"),36)
	for side in [-1,1]:
		_gate(Vector3(side*7,0,-3),3.2,0.8,Color("7b715d"))
		_lantern_small(_room,Vector3(side*5,1.6,2),Color("c2d5bb"),0.9)
	if id==6:
		_pavilion(Vector3(0,0,-6),1.2)
		_box(_room,Vector3(0,0.8,-3),Vector3(5.5,0.25,1.2),Color("645e4c"))
		for i in range(5): _box(_room,Vector3(-2+i,1.01,-3),Vector3(0.5,0.12,0.8),Color("c4bb98"))
		_torus(_room,Vector3(0,0.15,2),4.1,4.2,Color("c2aa79"),Vector3.ZERO)
	elif id in [2,4]:
		_pavilion(Vector3(0,0,-4),0.8)
		_box(_room,Vector3(-3,0.6,3),Vector3(1.5,0.15,0.7),Color("827558"))
		for i in range(3): _box(_room,Vector3(-3.4+i*.4,0.72,3),Vector3(.3,.03,.45),Color("d1c59d"))
	elif id in [3,5]:
		_box(_room,Vector3(0,1.5,-3),Vector3(2.3,3,0.6),Color("7f8876"))
		for i in range(6): _box(_room,Vector3(0,2.6-i*.4,-2.68),Vector3(1.4,.08,.03),Color("d5c59d"))
	else:
		for side in [-1,1]: _pavilion(Vector3(side*5,0,3),0.65)


func _ground_dressing(home: bool) -> void:
	# Cosmetic randomness is isolated from landmarks, obstacles and rewards.
	var decor_rng := RandomNumberGenerator.new()
	decor_rng.seed = map_seed + 170017
	var dressing := Node3D.new()
	dressing.name = "GroundDressing"
	_room.add_child(dressing)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var radius: float = 18.0 if home else 52.0
	var count: int = 100 if home else 340
	for i in range(count):
		var angle: float = decor_rng.randf() * TAU
		var distance: float = sqrt(decor_rng.randf()) * radius
		var center := Vector3(cos(angle) * distance, 0.015, sin(angle) * distance)
		if home and distance < 8.0: continue
		if not home and (_near_landmark(center, 4.5) or _in_ferry_water(center)): continue
		for blade in range(5):
			var turn: float = decor_rng.randf() * TAU
			var reach: float = decor_rng.randf_range(0.25, 0.65)
			var tip: Vector3 = center + Vector3(cos(turn)*reach, decor_rng.randf_range(0.12,0.36), sin(turn)*reach)
			var side := Vector3(-sin(turn),0,cos(turn))*0.045
			var mid: Vector3 = center.lerp(tip,0.45) + Vector3.UP*0.07
			for vertex in [center, mid+side, tip, center, tip, mid-side]: surface.add_vertex(vertex)
	surface.generate_normals()
	var grass := MeshInstance3D.new()
	grass.name = "Meadow"
	grass.mesh = surface.commit()
	var colors: Array[Color] = [Color("78876a"),Color("968a70"),Color("72908b"),Color("8b927b"),Color("a59377"),Color("858778")]
	grass.material_override = _material(colors[clampi(chapter-1,0,5)],0,true)
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dressing.add_child(grass)
	# Low stones and moss form irregular patches, leaving movement unobstructed.
	for i in range(18 if home else 48):
		var angle: float = decor_rng.randf()*TAU
		var distance: float = decor_rng.randf_range(9.0,radius)
		var center := Vector3(cos(angle)*distance,0.015,sin(angle)*distance)
		if not home and (_near_landmark(center,5.0) or _in_ferry_water(center)): continue
		var stone := _cylinder(dressing,center,0.3,0.4,0.055,Color("a3a796"),5)
		stone.scale = Vector3(decor_rng.randf_range(0.7,1.6),1,decor_rng.randf_range(0.5,1.1))
		stone.rotation.y = angle
	_batch_static(dressing)


func _in_ferry_water(pos: Vector3) -> bool:
	if chapter!=1 or landmarks.size()<7: return false
	for entry in [[3,Vector3(8,0,-5),5.0,5.5],[4,Vector3(-6,0,-5),5.1,4.9]]:
		var delta: Vector3=pos-landmarks[entry[0]]["pos"]-entry[1]
		if pow(delta.x/entry[2],2)+pow(delta.z/entry[3],2)<1.0: return true
	return false
