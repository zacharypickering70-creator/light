extends CanvasLayer

signal finished
var pages: Array = []
var page_index: int = -1
var ink: Control
var heading: Label
var prose: Label
var footer: Label
var turning: Tween
var closed: bool = false
var page_buttons: Array[Button]=[]
var touches: Dictionary={}
var reading: ScrollContainer

class Leaf extends Control:
	var lotus: bool = false
	var river: bool = false
	var mountain: bool = false
	func _draw() -> void:
		var r := Rect2(Vector2(18,18),size-Vector2(36,36))
		draw_rect(r,Color("e8ddbd"))
		draw_rect(r.grow(-9),Color("8c795c"),false,2)
		draw_line(Vector2(52,32),Vector2(52,size.y-32),Color("b5a17e"),2)
		for y in range(60,int(size.y)-35,35):
			draw_circle(Vector2(35,y),3,Color("675540"))
		var c := Vector2(size.x-120,size.y*0.52)
		var tint := Color(0.45,0.30,0.22,0.22)
		if mountain:
			draw_polyline(PackedVector2Array([c+Vector2(-70,60),c+Vector2(-30,-40),c+Vector2(-5,0),c+Vector2(25,-75),c+Vector2(70,60)]),tint,3,true)
			draw_arc(c+Vector2(10,-10),24,0,TAU,40,tint,2,true)
			draw_line(c+Vector2(10,-25),c+Vector2(10,5),tint,4)
		elif river:
			draw_rect(Rect2(c-Vector2(40,55),Vector2(80,110)),tint,false,3)
			for i in range(5): draw_line(c+Vector2(-25,-35+i*18),c+Vector2(20,-35+i*18),tint,2)
			draw_line(c+Vector2(30,-70),c+Vector2(-25,65),tint,5)
			for i in range(3): draw_arc(c+Vector2(0,60+i*12),70,0.1,PI-0.1,32,tint,2,true)
		elif lotus:
			for i in range(8):
				var a: float=i*TAU/8
				draw_arc(c+Vector2(cos(a),sin(a))*28,33,0,TAU,40,tint,2,true)
			draw_circle(c,16,tint)
		else:
			for i in range(4): draw_arc(c+Vector2(0,25+i*14),65,0.15,PI-0.15,32,tint,2,true)
			draw_polyline(PackedVector2Array([c+Vector2(-66,-12),c+Vector2(-35,12),c+Vector2(40,12),c+Vector2(65,-12)]),tint,4,true)
			draw_line(c+Vector2(-10,-65),c+Vector2(-10,8),tint,4)
			draw_line(c+Vector2(-10,-65),c+Vector2(33,-32),tint,2)
	func _ready() -> void:
		resized.connect(queue_redraw)

func open(chapter: int, content: Array, ui_theme: Theme) -> void:
	layer=40
	pages=content
	var shade:=ColorRect.new()
	shade.color=Color(0.04,0.06,0.055,0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var leaf:=Leaf.new()
	leaf.lotus=chapter==2
	leaf.river=chapter==3
	leaf.mountain=chapter==4
	leaf.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(leaf)
	ink=Control.new()
	ink.theme=ui_theme
	ink.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	leaf.add_child(ink)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,76)
	for side in ["top","bottom"]: margin.add_theme_constant_override("margin_"+side,40)
	ink.add_child(margin)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	margin.add_child(column)
	heading=Label.new()
	heading.add_theme_font_size_override("font_size",27)
	heading.add_theme_color_override("font_color",Color("863c30"))
	column.add_child(heading)
	var scroll:=ScrollContainer.new()
	reading=scroll
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	prose=Label.new()
	prose.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	prose.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	prose.add_theme_font_size_override("font_size",25)
	prose.add_theme_color_override("font_color",Color("38352c"))
	prose.add_theme_constant_override("line_spacing",8)
	scroll.add_child(prose)
	footer=Label.new()
	footer.add_theme_font_size_override("font_size",15)
	column.add_child(footer)
	var row:=HBoxContainer.new()
	row.alignment=BoxContainer.ALIGNMENT_END
	column.add_child(row)
	for title in ["略过此卷","翻页 / 继续"]:
		var button:=Button.new()
		button.text=title
		button.custom_minimum_size=Vector2(145,48)
		button.focus_mode=Control.FOCUS_NONE
		row.add_child(button)
		page_buttons.append(button)
		if title=="略过此卷": button.pressed.connect(close)
		else: button.pressed.connect(next_page)
	next_page()

func next_page() -> void:
	if closed: return
	if turning: turning.kill()
	page_index+=1
	if page_index>=pages.size():
		close()
		return
	heading.text=pages[page_index]["title"]
	prose.text=pages[page_index]["text"]
	reading.scroll_vertical=0
	footer.text="烬灯行 · 残卷　%d / %d　｜　可翻页，长文可滑动"%[page_index+1,pages.size()]
	ink.modulate.a=0
	turning=create_tween()
	turning.tween_property(ink,"modulate:a",1.0,1.1)
	# Reading time follows the amount of text; manual paging is always available.
	turning.tween_interval(maxf(8.0,prose.text.length()/5.0))
	turning.tween_property(ink,"modulate:a",0.0,1.3)
	turning.tween_callback(next_page)

func close() -> void:
	if closed: return
	closed=true
	if turning: turning.kill()
	finished.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if closed: return
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if event.device==InputEvent.DEVICE_ID_EMULATION: get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		get_viewport().set_input_as_handled()
		if event.pressed:
			var target: Button=null
			for button in page_buttons:
				if button.get_global_rect().has_point(event.position): target=button
			touches[event.index]={"start":event.position,"button":target,"scroll":reading.scroll_vertical}
			if turning: turning.pause()
		elif touches.has(event.index):
			var saved: Dictionary=touches[event.index]
			touches.erase(event.index)
			if turning and touches.is_empty(): turning.play()
			if not event.canceled and is_instance_valid(saved["button"]) and event.position.distance_to(saved["start"])<18:
				saved["button"].pressed.emit()
	elif event is InputEventScreenDrag and touches.has(event.index):
		get_viewport().set_input_as_handled()
		var saved: Dictionary=touches[event.index]
		if saved["button"]==null:
			reading.scroll_vertical=int(saved["scroll"]+saved["start"].y-event.position.y)
