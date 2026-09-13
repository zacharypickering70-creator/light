extends RefCounted

static func dress(w: Node3D, id: int) -> void:
	var detail := Node3D.new()
	detail.name = "FerryDetails"
	w._room.add_child(detail)
	if id in [3,4]:
		var center := Vector3(9,0,-5) if id==3 else Vector3(-6,0,-5)
		# Reeds grow around the water's edge, leaving the central fighting space clear.
		for i in range(15):
			var angle: float = i*TAU/15
			var base: Vector3 = center+Vector3(cos(angle),0,sin(angle))*(5.1 if id==3 else 4.9)
			for j in range(3):
				var tip: Vector3 = base+Vector3((j-1)*0.18,0.7+(i%4)*0.12,j*0.12)
				w._beam(detail,base,tip,0.018,Color("69705a"))
				w._cylinder(detail,tip,0.045,0.065,0.22,Color("b4a07c"),5)
			w._polygon_mesh(detail,PackedVector3Array([base,base+Vector3(0.4,0.4,0.1),base+Vector3(0.6,0.18,0.1)]),Color("69765e"))
		for i in range(4):
			var p: Vector3=center+Vector3(-1.3+i*0.75,0.13,-0.8+(i%2)*1.3)
			w._box(detail,p,Vector3(0.36,0.08,0.32),Color("766346"))
			w._cylinder(detail,p+Vector3.UP*0.13,0.045,0.07,0.18,Color("d89755"),6,1)
	if id==3:
		for x in [-2.0,0.0]:
			w._beam(detail,Vector3(x,0,-7),Vector3(x,1.7,-7),0.075,Color("62513e"))
		for i in range(6):
			var z: float=-7.0+i*0.21
			w._beam(detail,Vector3(-2,1.5-i*0.12,z),Vector3(0,1.4-i*0.12,z),0.012,Color("a29273"))
		for i in range(5):
			var x: float=-2+i*0.5
			w._beam(detail,Vector3(x,1.5,-7),Vector3(x,0.8,-5.95),0.012,Color("a29273"))
	elif id==1:
		for i in range(5):
			w._box(detail,Vector3(-6+i*0.65,0.05,-2.8),Vector3(0.58,0.06,0.36),Color("a59b7e"))
	elif id==2:
		for i in range(3):
			w._cylinder(detail,Vector3(-5.4+i*0.38,0.83,-4),0.07,0.06,0.12,Color("d1b98c"),8)
	elif id==5:
		for side in [-1,1]:
			w._cylinder(detail,Vector3(-4+side*1.25,0.15,-4),0.25,0.3,0.3,Color("6a6a59"),8)
			for i in range(3): w._beam(detail,Vector3(-4+side*1.25+i*0.06,0.3,-4),Vector3(-4+side*1.25+i*0.06,0.85,-4),0.012,Color("a97854"))
	elif id==6:
		for side in [-1,1]:
			for i in range(8):
				var link: MeshInstance3D=w._torus(detail,Vector3(side*(3.5+i*0.46),0.13,-8.2),0.12,0.17,Color("596157"),Vector3(PI/2 if i%2 else 0,0,0))
				link.scale.x=1.4
	if detail.get_child_count()>0: w._batch_static(detail)

static func boat(w: Node3D, pos: Vector3) -> void:
	var boat_root := Node3D.new()
	boat_root.name = "PlankedBoat"
	w._room.add_child(boat_root)
	boat_root.position=pos
	for side in [-1,1]:
		var rim: Array[Vector3]=[Vector3(0,0.55,-3),Vector3(side*0.72,0.45,-1.8),Vector3(side*0.82,0.40,1.3),Vector3(0,0.6,2.8)]
		for i in range(3):
			w._beam(boat_root,rim[i],rim[i+1],0.09,Color("65553f"))
			w._polygon_mesh(boat_root,PackedVector3Array([rim[i],rim[i+1],Vector3(rim[i+1].x*0.6,0.12,rim[i+1].z),rim[i],Vector3(rim[i+1].x*0.6,0.12,rim[i+1].z),Vector3(rim[i].x*0.6,0.12,rim[i].z)]),Color("7d7057"))
	for i in range(10):
		var z: float=-2.3+i*0.48
		var width: float=1.3*(1.0-pow(absf(z)/3.0,2))
		w._box(boat_root,Vector3(0,0.16,z),Vector3(width,0.07,0.43),Color("968267"))
	for z in [-1.1,1.0]: w._box(boat_root,Vector3(0,0.40,z),Vector3(1.4,0.09,0.3),Color("67583e"))
	w._beam(boat_root,Vector3(-1,0.55,-1.8),Vector3(1.25,0.60,1.5),0.045,Color("a29370"))
	w._box(boat_root,Vector3(1.25,0.60,1.5),Vector3(0.24,0.07,0.7),Color("a29370"))
	w._batch_static(boat_root)


static func water(w: Node3D, pos: Vector3, width: float, depth: float) -> void:
	var bank: Array[Vector3]=[]
	var surface: Array[Vector3]=[]
	for i in range(40):
		var a: float=i*TAU/40
		var b: float=(i+1)*TAU/40
		var ra: float=1.0+0.045*sin(a*5)+0.025*cos(a*9)
		var rb: float=1.0+0.045*sin(b*5)+0.025*cos(b*9)
		var pa:=Vector3(cos(a)*width*ra,0,sin(a)*depth*ra)
		var pb:=Vector3(cos(b)*width*rb,0,sin(b)*depth*rb)
		surface.append_array([pos,pos+pa,pos+pb])
		bank.append_array([pos+pa,pos+pa*1.06,pos+pb*1.06,pos+pa,pos+pb*1.06,pos+pb])
	var edge: MeshInstance3D=w._polygon_mesh(w._room,PackedVector3Array(bank),Color("7c8571"))
	edge.name="WaterBank"
	var pool: MeshInstance3D=w._polygon_mesh(w._room,PackedVector3Array(surface),Color("71958b"))
	pool.name="FerryWater"
	var material := ShaderMaterial.new()
	material.shader=preload("res://assets/ferry_water.gdshader")
	pool.material_override=material
	pool.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
