extends RefCounted

static func finish(label: Label3D) -> void:
	var weight:=FontVariation.new()
	weight.base_font=load("res://assets/NotoSansSC.ttf")
	weight.variation_opentype={2003265652:600.0}
	label.font=weight
	label.render_priority=2
	var width: int=ceili(weight.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.font_size).x)+28
	var height: int=label.font_size+22
	var paper:=Image.create(width,height,false,Image.FORMAT_RGBA8)
	paper.fill(Color("a0926e"))
	paper.fill_rect(Rect2i(2,2,width-4,height-4),Color("202924"))
	var plate:=Sprite3D.new()
	plate.name="InkNameplate"
	plate.texture=ImageTexture.create_from_image(paper)
	plate.pixel_size=label.pixel_size
	plate.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	plate.shaded=false
	plate.no_depth_test=true
	plate.render_priority=1
	plate.visibility_range_end=label.visibility_range_end
	plate.visibility_range_end_margin=label.visibility_range_end_margin
	label.add_child(plate)
