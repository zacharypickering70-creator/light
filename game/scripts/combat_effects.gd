extends RefCounted

static func swing(g: Node, origin: Vector3, facing: Vector3, reach: float, art: String, color: Color, combo: int) -> void:
	if g.effects.get_child_count()>150: return
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_angle: float = PI if art=="sweep" else acos(float(g.Techniques.ARTS[art]["arc"]))
	var center: float=atan2(facing.x,facing.z)
	var steps: int=32 if art=="sweep" else 22
	var width: float=0.38 if combo==3 else 0.23
	for i in range(steps):
		var a: float=center-half_angle+2.0*half_angle*i/steps
		var b: float=center-half_angle+2.0*half_angle*(i+1)/steps
		var taper_a: float=0.25+0.75*sin(PI*float(i)/steps)
		var taper_b: float=0.25+0.75*sin(PI*float(i+1)/steps)
		var pa:=Vector3(sin(a),0,cos(a))
		var pb:=Vector3(sin(b),0,cos(b))
		var edge: Array[Vector3]=[pa*(reach+0.055),pb*(reach+0.055),pa*(reach-0.025),pb*(reach+0.055),pb*(reach-0.025),pa*(reach-0.025)]
		for point in edge:
			surface.set_color(Color(0.10,0.15,0.13,0.65))
			surface.add_vertex(point)
		var vertices: Array[Vector3]=[pa*reach,pb*reach,pa*(reach-width*taper_a),pb*reach,pb*(reach-width*taper_b),pa*(reach-width*taper_a)]
		for j in range(6):
			var outer: bool=j in [0,1,3]
			surface.set_color(Color(color.lightened(0.35) if outer else color,0.95 if outer else 0.05))
			surface.add_vertex(vertices[j])
	var node := MeshInstance3D.new()
	node.name="AttackBrush"
	node.mesh=surface.commit()
	var material := StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo=true
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material.albedo_color=Color.WHITE
	node.material_override=material
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.effects.add_child(node)
	node.position=origin+Vector3.UP*0.70
	var tween: Tween=g.create_tween().set_parallel()
	tween.tween_property(material,"albedo_color:a",0.0,0.22 if combo==3 else 0.16)
	tween.tween_property(node,"scale",Vector3.ONE*1.035,0.16)
	tween.chain().tween_callback(node.queue_free)
	if art=="thrust" or (art=="flurry" and combo==3):
		g._bolt(origin+Vector3.UP*0.8,origin+facing*(reach if art=="thrust" else 6.0)+Vector3.UP*0.8,color)
