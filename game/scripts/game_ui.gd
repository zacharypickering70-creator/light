extends CanvasLayer

signal action(id: String)
const Techniques=preload("res://scripts/techniques.gd")
var _skill_buttons: Array[Button]=[]
var _ultimate_button: Button

const INK: Color = Color("ded9c9")
const PAPER: Color = Color("2c302b")
const GOLD: Color = Color("805342")
const MUTED: Color = Color("4e574a")
const RED: Color = Color("9c4035")
const JADE: Color = Color("637565")

signal volume_changed(channel: String, value: float)
var _audio_controls: VBoxContainer
var _audio_sliders: Dictionary={}
var _audio_touches: Dictionary={}
var move_vector: Vector2 = Vector2.ZERO
var attack_held: bool = false

var _root: Control
var _combat: Control
var _map_view: InkMap
var _modal_touches: Dictionary = {}
var _resource_text: Label
var _progress_label: Label
var _room_label: Label
var _objective_label: Label
var _enemy_label: Label
var _ash_label: Label
var _health: ProgressBar
var _health_text: Label
var _energy: ProgressBar
var _experience: ProgressBar
var _experience_text: Label
var _experience_fill: StyleBoxFlat
var _experience_hint: Label
var _boss_box: VBoxContainer
var _boss_label: Label
var _boss_bar: ProgressBar
var _dash_button: Button
var _flame_button: Button
var _combat_buttons: Dictionary = {}
var _combat_touches: Dictionary = {}
var _mouse_combat_action: String = ""
var _emulated_mouse_captured: bool = false
var _modal: Control
var _modal_panel: PanelContainer
var _modal_eyebrow: Label
var _modal_title: Label
var _modal_description: Label
var _modal_grid: GridContainer
var _modal_scroll: ScrollContainer
var _modal_buttons: Array = []
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_timer: Timer
var _joystick: TouchStick
var _is_touch: bool = false
var _combat_requested: bool = false


class InkMap extends Control:
	var points: Array=[]
	var player: Vector2=Vector2.ZERO
	var boss_active: bool=false
	var home: bool=false
	func _draw() -> void:
		var center: Vector2=size*0.5
		draw_style_box(_paper_box(),Rect2(Vector2.ZERO,size))
		draw_arc(center,62,0,TAU,72,Color(0.5,0.5,0.45,0.35),1,true)
		var font: Font=get_theme_default_font()
		draw_string(font,Vector2(13,23),("竹隐居" if home else "已探山水"),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("424b40"))
		for item in points:
			var p: Vector3=item["pos"]
			var dot: Vector2=center+Vector2(p.x,p.z)*1.04
			var id: int=item["id"]
			var color: Color=Color("9d3c31") if id==6 and boss_active else Color("586458")
			draw_circle(dot,4 if id==6 else 3,color)
			var label: String=[("家" if home else "落"),"竹","亭","渡","汀","碑","首领"][id]
			draw_string(font,dot+Vector2(5,4),label,HORIZONTAL_ALIGNMENT_LEFT,-1,11,color)
		var hero: Vector2=center+player*1.04
		draw_circle(hero,4.5,Color("b44935"))
		draw_arc(hero,7,0,TAU,20,Color("f9f3e2"),1.5,true)
		draw_string(font,Vector2(13,size.y-10),"朱砂 · 你",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("61695f"))
	func _paper_box() -> StyleBoxFlat:
		var box:=StyleBoxFlat.new()
		box.bg_color=Color(0.93,0.91,0.85,0.93)
		box.border_color=Color(0.45,0.45,0.40,0.5)
		box.set_border_width_all(1)
		box.set_corner_radius_all(3)
		return box


class TouchStick extends Control:

	signal moved(value: Vector2)
	var enabled: bool = true
	var _finger: int = -1
	var _value: Vector2 = Vector2.ZERO
	var _radius: float = 63.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func reset() -> void:
		_finger = -1
		_value = Vector2.ZERO
		moved.emit(_value)
		queue_redraw()

	func _input(event: InputEvent) -> void:
		if not enabled or not is_visible_in_tree():
			return
		if event is InputEventScreenTouch:
			var touch: InputEventScreenTouch = event as InputEventScreenTouch
			var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * touch.position
			if touch.pressed and _finger == -1 and Rect2(Vector2.ZERO, size).has_point(local):
				_finger = touch.index
				_update_value(local)
				get_viewport().set_input_as_handled()
			elif not touch.pressed and touch.index == _finger:
				reset()
				get_viewport().set_input_as_handled()
		elif event is InputEventScreenDrag:
			var drag: InputEventScreenDrag = event as InputEventScreenDrag
			if drag.index == _finger:
				var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * drag.position
				_update_value(local)
				get_viewport().set_input_as_handled()

	func _update_value(local: Vector2) -> void:
		_value = ((local - size * 0.5) / _radius).limit_length(1.0)
		var magnitude: float=_value.length()
		_value=Vector2.ZERO if magnitude<0.08 else _value.normalized()*pow(clampf((magnitude-0.08)/0.72,0,1),0.65)
		moved.emit(_value)
		queue_redraw()

	func _draw() -> void:
		var center: Vector2 = size * 0.5
		draw_circle(center, _radius, Color(0.04, 0.09, 0.10, 0.55))
		draw_arc(center, _radius, 0.0, TAU, 64, Color(0.74, 0.61, 0.38, 0.65), 1.5, true)
		draw_arc(center, _radius - 7.0, 0.0, TAU, 64, Color(0.74, 0.61, 0.38, 0.17), 1.0, true)
		var knob: Vector2 = center + _value * (_radius - 19.0)
		draw_circle(knob, 23.0, Color(0.74, 0.61, 0.38, 0.26))
		draw_arc(knob, 23.0, 0.0, TAU, 40, Color(0.91, 0.86, 0.71, 0.85), 1.5, true)
		draw_circle(knob, 3.0, Color(0.91, 0.86, 0.71, 0.9))


func _ready() -> void:
	layer = 20
	_is_touch = true
	_build_ui()
	get_viewport().size_changed.connect(_layout_modal)
	get_viewport().size_changed.connect(_apply_safe_area)
	call_deferred("_apply_safe_area")
	_combat.visible = false
	_modal.visible = false
	_toast_panel.visible = false


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var ui_theme: Theme = Theme.new()
	ui_theme.default_font_size = 18
	if ResourceLoader.exists("res://assets/NotoSansSC.ttf"):
		var readable_font: FontVariation = FontVariation.new()
		readable_font.base_font = load("res://assets/NotoSansSC.ttf") as Font
		readable_font.variation_opentype = {2003265652: 500.0}
		ui_theme.default_font = readable_font
	else:
		var system_font: SystemFont = SystemFont.new()
		system_font.font_names = PackedStringArray(["Noto Sans CJK SC", "Source Han Sans SC", "Microsoft YaHei", "sans-serif"])
		ui_theme.default_font = system_font
	ui_theme.set_color("font_color", "Label", PAPER)
	ui_theme.set_color("font_color", "Button", PAPER)
	ui_theme.set_color("font_hover_color", "Button", Color("1b211d"))
	ui_theme.set_color("font_pressed_color", "Button", Color("18211c"))
	ui_theme.set_color("font_disabled_color", "Button", Color("9b9b8f"))
	ui_theme.set_stylebox("normal", "Button", _box(Color("e4dfd0"), Color("a59e8b"), 5, 1))
	ui_theme.set_stylebox("hover", "Button", _box(Color("f2ead6"), GOLD, 5, 1))
	ui_theme.set_stylebox("pressed", "Button", _box(Color("cbc8b8"), PAPER, 5, 1))
	ui_theme.set_stylebox("disabled", "Button", _box(Color("d9d5c7"), Color("bdb9ac"), 5, 1))
	ui_theme.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), GOLD, 5, 2))
	_root.theme = ui_theme
	_build_hud()
	_build_map_ui()
	_build_modal()
	_build_toast()


func _build_hud() -> void:
	_combat = Control.new()
	_combat.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_combat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_combat)

	var left_panel: PanelContainer = PanelContainer.new()
	left_panel.position = Vector2(18, 18)
	left_panel.custom_minimum_size = Vector2(270, 0)
	left_panel.add_theme_stylebox_override("panel", _box(Color(0.91, 0.89, 0.83, 0.94), Color(0.5, 0.47, 0.34, 0.4), 4, 1))
	left_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat.add_child(left_panel)
	var left_margin: MarginContainer = _margin(12, 9, 12, 10)
	left_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_panel.add_child(left_margin)
	var stats: VBoxContainer = VBoxContainer.new()
	stats.add_theme_constant_override("separation", 7)
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_margin.add_child(stats)
	var caption: HBoxContainer = HBoxContainer.new()
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats.add_child(caption)
	var name_label: Label = _label("提灯人", 18, PAPER)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.add_child(name_label)
	_health_text = _label("100 / 100", 15, MUTED)
	caption.add_child(_health_text)
	_health = _bar(RED, 10)
	stats.add_child(_health)
	_energy = _bar(JADE, 5)
	stats.add_child(_energy)
	_experience_text = _label("经验 0 / 40", 14, PAPER)
	stats.add_child(_experience_text)
	_experience = _bar(GOLD, 10)
	_experience_fill = _experience.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	_experience.add_theme_stylebox_override("fill", _experience_fill)
	stats.add_child(_experience)
	_resource_text=_label("",13,PAPER)
	stats.add_child(_resource_text)

	var quest_bg:=Panel.new()
	quest_bg.position=Vector2(18,166)
	quest_bg.size=Vector2(295,164)
	quest_bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
	quest_bg.add_theme_stylebox_override("panel",_box(Color(0.93,0.91,0.85,0.94),Color(0.5,0.47,0.34,0.25),3,1))
	_combat.add_child(quest_bg)
	var quest_panel: VBoxContainer = VBoxContainer.new()
	quest_panel.position = Vector2(26, 172)
	quest_panel.custom_minimum_size = Vector2(275, 0)
	quest_panel.add_theme_constant_override("separation", 6)
	quest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat.add_child(quest_panel)
	_room_label = _label("残灯庵", 20, PAPER)
	_room_label.add_theme_color_override("font_shadow_color", Color(0.96, 0.94, 0.88, 0.75))
	_room_label.add_theme_constant_override("shadow_offset_x", 1)
	_room_label.add_theme_constant_override("shadow_offset_y", 2)
	quest_panel.add_child(_room_label)
	_objective_label = _label("循灯而行，寻回命火。", 16, PAPER)
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_panel.add_child(_objective_label)
	_enemy_label = _label("", 14, GOLD)
	quest_panel.add_child(_enemy_label)

	var top_right: HBoxContainer = HBoxContainer.new()
	top_right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	top_right.offset_left = -273
	top_right.offset_right = -28
	top_right.offset_top = 25
	top_right.offset_bottom = 70
	top_right.add_theme_constant_override("separation", 16)
	top_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat.add_child(top_right)
	_ash_label = _label("烬砂  0", 18, GOLD)
	_ash_label.add_theme_stylebox_override("normal",_box(Color(0.93,0.91,0.85,0.95),Color.TRANSPARENT,3,0))
	_ash_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_right.add_child(_ash_label)
	var pause_button: Button = _button("暂歇  Ⅱ", "pause", Vector2(105, 44))
	pause_button.add_theme_font_size_override("font_size", 16)
	top_right.add_child(pause_button)
	_combat_buttons["pause"] = pause_button

	_boss_box = VBoxContainer.new()
	_boss_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_boss_box.offset_left = -195
	_boss_box.offset_right = 195
	_boss_box.offset_top = 29
	_boss_box.offset_bottom = 81
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.add_theme_constant_override("separation", 8)
	_combat.add_child(_boss_box)
	_boss_label = _label("", 22, INK)
	_boss_label.add_theme_color_override("font_outline_color",Color("192420"))
	_boss_label.add_theme_constant_override("outline_size",4)
	var boss_plate:=StyleBoxFlat.new()
	boss_plate.bg_color=Color(0.10,0.14,0.12,0.9)
	boss_plate.content_margin_top=3
	boss_plate.content_margin_bottom=3
	_boss_label.add_theme_stylebox_override("normal",boss_plate)
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_box.add_child(_boss_label)
	_boss_bar = _bar(RED, 7)
	_boss_box.add_child(_boss_bar)
	_boss_box.visible = false

	var ability_row:=Control.new()
	ability_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	ability_row.offset_left=-425
	ability_row.offset_right=-18
	ability_row.offset_top=-354
	ability_row.offset_bottom=-18
	ability_row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_combat.add_child(ability_row)
	var attack_button: Button=_round_button("普攻","attack","attack",108,Color("bd9c64"))
	attack_button.position=Vector2(298,210)
	ability_row.add_child(attack_button)
	_combat_buttons["attack"]=attack_button
	var positions: Array[Vector2]=[Vector2(165,232),Vector2(190,127),Vector2(278,27)]
	for i in range(3):
		var button: Button=_round_button("学习","skill_"+str(i),"locked",86,Color("96b7a5"))
		button.position=positions[i]
		ability_row.add_child(button)
		_skill_buttons.append(button)
		_combat_buttons["skill_"+str(i)]=button
	_flame_button=_skill_buttons[0]
	_dash_button=_round_button("踏影","dash","dash",80,Color("afbaaa"))
	_dash_button.position=Vector2(65,234)
	ability_row.add_child(_dash_button)
	_combat_buttons["dash"]=_dash_button
	_ultimate_button=_round_button("绝技","ultimate","ultimate",92,Color("d8a5b8"))
	_ultimate_button.position=Vector2(76,118)
	ability_row.add_child(_ultimate_button)
	_combat_buttons["ultimate"]=_ultimate_button
	var auto_button: Button=_button("自动：关","auto",Vector2(104,48))
	auto_button.position=Vector2(153,56)
	auto_button.add_theme_font_size_override("font_size",16)
	ability_row.add_child(auto_button)
	_combat_buttons["auto"]=auto_button
	_joystick = TouchStick.new()
	_joystick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_joystick.offset_left = 35
	_joystick.offset_right = 195
	_joystick.offset_top = -200
	_joystick.offset_bottom = -40
	_joystick.visible = _is_touch
	_joystick.moved.connect(_on_stick_moved)
	_combat.add_child(_joystick)
	_experience_hint = _label("", 19, Color("ffe1a1"))
	_experience_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_experience_hint.offset_left = -155
	_experience_hint.offset_right = 155
	_experience_hint.offset_top = -122
	_experience_hint.offset_bottom = -99
	_experience_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_experience_hint.add_theme_color_override("font_outline_color", Color("242c27"))
	_experience_hint.add_theme_constant_override("outline_size", 5)
	_experience_hint.visible = false
	_combat.add_child(_experience_hint)


func _build_modal() -> void:
	_modal=Control.new()
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal.mouse_filter=Control.MOUSE_FILTER_STOP
	_root.add_child(_modal)
	var dimmer:=ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color=Color(0.28,0.29,0.26,0.43)
	_modal.add_child(dimmer)
	_modal_panel=PanelContainer.new()
	_modal_panel.add_theme_stylebox_override("panel",_box(Color(0.92,0.90,0.84,0.98),Color("766a4f"),6,1))
	_modal.add_child(_modal_panel)
	_modal_scroll=ScrollContainer.new()
	_modal_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	_modal_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	_modal_panel.add_child(_modal_scroll)
	var margin: MarginContainer=_margin(35,27,35,27)
	margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_modal_scroll.add_child(margin)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",14)
	margin.add_child(content)
	_modal_eyebrow=_label("烬灯行",13,GOLD)
	content.add_child(_modal_eyebrow)
	_modal_title=_label("烬灯行",37,PAPER)
	content.add_child(_modal_title)
	_modal_description=_label("",18,Color("42493f"))
	_modal_description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_modal_description.add_theme_constant_override("line_spacing",4)
	content.add_child(_modal_description)
	_audio_controls=VBoxContainer.new()
	_audio_controls.add_theme_constant_override("separation",12)
	content.add_child(_audio_controls)
	_audio_controls.hide()
	var divider:=ColorRect.new()
	divider.custom_minimum_size.y=1
	divider.color=Color(0.4,0.4,0.35,0.3)
	content.add_child(divider)
	_modal_grid=GridContainer.new()
	_modal_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_modal_grid.add_theme_constant_override("h_separation",13)
	_modal_grid.add_theme_constant_override("v_separation",12)
	content.add_child(_modal_grid)
	var footer: Label=_label("一盏残灯，照见归途。",13,Color("77786c"))
	footer.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(footer)


func _build_toast() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast_panel.offset_left = -250
	_toast_panel.offset_right = 250
	_toast_panel.offset_top = -180
	_toast_panel.offset_bottom = -124
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.add_theme_stylebox_override("panel", _box(Color(0.92, 0.89, 0.80, 0.97), GOLD, 5, 1))
	_root.add_child(_toast_panel)
	var margin: MarginContainer = _margin(18, 10, 18, 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.add_child(margin)
	_toast_label = _label("", 18, PAPER)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(_toast_label)
	_toast_timer = Timer.new()
	_toast_timer.wait_time = 3.0
	_toast_timer.one_shot = true
	_toast_timer.timeout.connect(_hide_toast)
	add_child(_toast_timer)


func update_hud(data: Dictionary) -> void:
	if not is_instance_valid(_root):
		return
	var hp: float = float(data.get("hp", 100.0))
	var maximum_hp: float = maxf(1.0, float(data.get("max_hp", 100.0)))
	_health.max_value = maximum_hp
	_health.value = hp
	_health_text.text = "%d / %d" % [ceili(maxf(0.0, hp)), ceili(maximum_hp)]
	_energy.max_value = maxf(1.0, float(data.get("max_energy", 100.0)))
	_energy.value = float(data.get("energy", 100.0))
	_resource_text.text="灯火 %d  ·  学习点 %d"%[int(_energy.value),int(data.get("study",0))]
	if float(data.get("shield",0))>0: _resource_text.text+="  ·  盾 %d"%int(data["shield"])
	_experience.max_value = maxf(1.0, float(data.get("xp_next", 100.0)))
	_experience.value = float(data.get("xp", 0.0))
	var near_level: bool = _experience.ratio >= 0.8
	_experience_text.text = "经验 %d / %d" % [int(_experience.value), int(_experience.max_value)]
	if near_level: _experience_text.text += " · 即将升级"
	if data.get("home", false): _experience_text.text = "出发后击败敌人，积累经验"
	_experience_fill.bg_color = Color("b66a23") if near_level else GOLD
	_experience_text.add_theme_color_override("font_color", Color("864416") if near_level else PAPER)
	_experience_hint.visible = near_level and not data.get("home", false)
	_experience_hint.text = "即将升级 · 还差 %d 经验" % int(_experience.max_value - _experience.value)
	_room_label.text = str(data.get("title","残灯庵"))
	_objective_label.text = str(data.get("objective", "循灯而行，寻回命火。"))
	var remaining: int = int(data.get("enemies", 0))
	_enemy_label.text = "%d 连斩 · 附近 %d" % [int(data.get("streak",0)),remaining] if int(data.get("streak",0))>1 else "附近敌人 %d"%remaining
	if data.get("home",false): _enemy_label.text="安全区域 · 不会出现敌人"
	_ash_label.text = "烬砂  %d" % int(data.get("ash", 0))
	var boss_maximum: float = float(data.get("boss_max", 0.0))
	var boss_hp: float = float(data.get("boss_hp", 0.0))
	_boss_box.visible = boss_maximum > 0.0 and boss_hp > 0.0
	_boss_bar.max_value = maxf(1.0, boss_maximum)
	_boss_bar.value = boss_hp
	_boss_label.text = str(data.get("boss_name", "守灯人"))
	var dash_cd: float = maxf(0.0, float(data.get("dash_cd", 0.0)))
	var flame_cd: float = maxf(0.0, float(data.get("flame_cd", 0.0)))
	_ability_caption(_dash_button,"%.1f"%dash_cd if dash_cd>0.05 else "踏影")
	var learned: Array=data.get("learned",[])
	var cooldowns: Array=data.get("skill_cds",[0.0,0.0,0.0])
	for i in range(3):
		var button: Button=_skill_buttons[i]
		var ready: bool=i<learned.size()
		var skill: String=learned[i] if ready else "locked"
		_ability_caption(button,Techniques.SKILLS[skill]["name"] if ready else ("学习" if i==0 or int(data.get("level",1))>=(3 if i==1 else 5) else "%d级"%(3 if i==1 else 5)))
		var cooldown_text: Label=button.get_meta("cooldown")
		var costs: Array=data.get("skill_costs",[0,0,0])
		cooldown_text.text=("%.1f"%float(cooldowns[i]) if float(cooldowns[i])>0.05 else ("缺灯火" if ready and float(data.get("energy",0))<float(costs[i]) else ""))
		var glyph: TextureRect=button.get_meta("glyph")
		if glyph.get_meta("skill","")!=skill:
			glyph.texture=load("res://assets/ui/"+skill+".svg")
			glyph.set_meta("skill",skill)
			glyph.modulate=Color(Techniques.SKILLS[skill]["color"]) if ready else Color.WHITE
		glyph.modulate.a=0.22 if float(cooldowns[i])>0.05 else 1.0
		button.modulate=Color.WHITE if ready and float(cooldowns[i])<=0 else Color(0.68,0.72,0.69)
	var charge: float=float(data.get("ultimate_charge",0))
	_ability_caption(_ultimate_button,str(data.get("ultimate_name","绝技")) if charge>=100 else "%d%%"%int(charge))
	var ult: String=data.get("ultimate_id","lotus")
	var ult_glyph: TextureRect=_ultimate_button.get_meta("glyph")
	if ult_glyph.get_meta("ult","")!=ult:
		var icons: Dictionary={"lotus":"ultimate","tempest":"thunder","sanctuary":"barrier","blizzard":"frost","hurricane":"vortex","sword_rain":"darts","venom":"poison","avatar":"haste","void":"weak","meteor":"fire"}
		ult_glyph.texture=load("res://assets/ui/"+icons[ult]+".svg")
		ult_glyph.modulate=Color(Techniques.ULTIMATES[ult]["color"])
		ult_glyph.set_meta("ult",ult)
	_ultimate_button.modulate=Color.WHITE if charge>=100 else Color(0.65,0.62,0.67)
	_combat_buttons["weapons"].visible=bool(data.get("home",false))
	_combat_buttons["techniques"].visible=bool(data.get("home",false))
	_combat_buttons["auto"].text="自动：开" if data.get("auto",false) else "自动：关"
	_combat_buttons["interact"].visible=data.get("interact_available",false)
	_combat_buttons["interact"].text="传送" if data.get("portal_near",false) else "交互"
	var elapsed: int=int(data.get("seconds",0))
	_progress_label.text="修为 %d  ·  %02d:%02d  ·  第 %d 波\n%s" % [int(data.get("level",1)),elapsed/60,elapsed%60,int(data.get("wave",0)),("首领已现身 · 距离 %d" % int(data.get("boss_dist",0))) if data.get("boss_spawned",false) else "首领：修为 %d / 本境6分钟"%int(data.get("boss_level",7))]
	if data.get("home",false): _progress_label.text="竹隐居 · 从传送阵出发，逐关向前"
	_map_view.points=data.get("map_points",[])
	_map_view.player=data.get("player_pos",Vector2.ZERO)
	_map_view.boss_active=data.get("boss_spawned",false)
	_map_view.home=data.get("home",false)
	_map_view.queue_redraw()
	_dash_button.modulate = Color(0.7, 0.75, 0.72, 1.0) if dash_cd > 0.05 else Color.WHITE



func _build_map_ui() -> void:
	_map_view=InkMap.new()
	_map_view.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_map_view.offset_left=-180
	_map_view.offset_right=-18
	_map_view.offset_top=82
	_map_view.offset_bottom=244
	_map_view.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_combat.add_child(_map_view)
	_progress_label=_label("",14,PAPER)
	_progress_label.position=Vector2(26,280)
	_progress_label.custom_minimum_size=Vector2(280,44)
	_combat.add_child(_progress_label)
	var utility:=HBoxContainer.new()
	utility.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	utility.offset_left=-304
	utility.offset_right=-18
	utility.offset_top=252
	utility.offset_bottom=300
	utility.add_theme_constant_override("separation",8)
	_combat.add_child(utility)
	for item in [["兵器","weapons"],["武学","techniques"],["行囊","inventory"]]:
		var button: Button=_button(item[0],item[1],Vector2(88,48))
		button.add_theme_font_size_override("font_size",18)
		utility.add_child(button)
		_combat_buttons[item[1]]=button
	var interact: Button=_button("交互","interact",Vector2(108,62))
	interact.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	interact.offset_left=-54
	interact.offset_right=54
	interact.offset_top=-95
	interact.offset_bottom=-33
	_combat.add_child(interact)
	_combat_buttons["interact"]=interact



func show_modal(title: String, description: String, buttons: Array, eyebrow: String = "") -> void:
	if not is_instance_valid(_root):
		return
	_audio_controls.hide()
	_audio_touches.clear()
	_modal_title.text = title
	_modal_description.text = description
	_modal_description.visible = not description.is_empty()
	_modal_eyebrow.text = eyebrow if not eyebrow.is_empty() else "ASHBOUND  /  烬灯行"
	_modal_buttons = buttons.duplicate()
	for child: Node in _modal_grid.get_children():
		_modal_grid.remove_child(child)
		child.queue_free()
	for item: Variant in _modal_buttons:
		if not item is Dictionary:
			continue
		var entry: Dictionary = item as Dictionary
		var id: String = str(entry.get("id", ""))
		var detail: String = str(entry.get("detail", ""))
		var button: Button = _button("", id, Vector2(0, 91 if detail.is_empty() else 113))
		button.set_meta("card_label", str(entry.get("label", "继续")))
		button.set_meta("card_detail", detail)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = bool(entry.get("disabled", false))
		button.clip_contents = true
		_modal_grid.add_child(button)
		var padding: MarginContainer = _margin(20, 14, 20, 14)
		padding.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		padding.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(padding)
		var copy: VBoxContainer = VBoxContainer.new()
		copy.alignment = BoxContainer.ALIGNMENT_CENTER
		copy.add_theme_constant_override("separation", 5)
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		padding.add_child(copy)
		var text_label: Label = _label(str(entry.get("label", "继续")), 21, PAPER)
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(text_label)
		if not detail.is_empty():
			var detail_label: Label = _label(detail, 15, MUTED)
			detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			copy.add_child(detail_label)
		if button.disabled:
			copy.modulate.a = 0.42
	_modal_scroll.scroll_vertical = 0
	_modal.visible = true
	_joystick.enabled = false
	_reset_combat_input()
	_toast_panel.hide()
	_layout_modal()
	call_deferred("_layout_modal")


func hide_modal() -> void:
	if is_instance_valid(_modal):
		_modal.hide()
		_joystick.enabled = _combat_requested
		get_viewport().gui_release_focus()


func toast(message: String) -> void:
	if not is_instance_valid(_toast_panel):
		return
	_toast_label.text = message
	_toast_panel.show()
	_toast_timer.start(3.0)


func set_combat_visible(value: bool) -> void:
	_combat_requested = value
	if not is_instance_valid(_combat):
		return
	_combat.visible = value
	_joystick.enabled = value and not _modal.visible
	if not value:
		_reset_combat_input()


func _input(event: InputEvent) -> void:
	if not is_instance_valid(_modal):
		return
	if _audio_controls.visible and _modal.visible:
		if event is InputEventScreenTouch:
			if event.pressed:
				for channel in _audio_sliders:
					var slider: HSlider=_audio_sliders[channel]
					if slider.get_global_rect().has_point(event.position):
						_audio_touches[event.index]=slider
						_audio_touch_value(slider,event.position)
						_emulated_mouse_captured=true
						get_viewport().set_input_as_handled()
						return
			elif _audio_touches.has(event.index):
				_audio_touches.erase(event.index)
				get_viewport().set_input_as_handled()
				return
		elif event is InputEventScreenDrag and _audio_touches.has(event.index):
			_audio_touch_value(_audio_touches[event.index],event.position)
			get_viewport().set_input_as_handled()
			return
	var combat_enabled: bool = _combat_requested and _combat.visible and not _modal.visible
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.device == InputEvent.DEVICE_ID_EMULATION:
			# Combat reads every touch independently; its emulated mouse must not click twice.
			# Keep consuming this mouse gesture if an attack or pause opened a modal.
			if combat_enabled or _emulated_mouse_captured:
				if mouse.button_index == MOUSE_BUTTON_LEFT:
					_emulated_mouse_captured = mouse.pressed
				get_viewport().set_input_as_handled()
			return
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if not mouse.pressed and not _mouse_combat_action.is_empty():
			_mouse_combat_action = ""
			_refresh_attack_held()
			get_viewport().set_input_as_handled()
			return
		if combat_enabled and mouse.pressed:
			var id: String = _combat_action_at(mouse.position)
			if not id.is_empty():
				_mouse_combat_action = id
				_refresh_attack_held()
				get_viewport().set_input_as_handled()
				action.emit(id)
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if _modal.visible:
			if touch.pressed:
				for child in _modal_grid.get_children():
					var card: Button=child as Button
					if card and card.get_global_rect().has_point(touch.position) and _modal_scroll.get_global_rect().has_point(touch.position):
						_modal_touches[touch.index]={"button":card,"pos":touch.position,"scroll":_modal_scroll.scroll_vertical,"dragged":false}
						_emulated_mouse_captured=true
						get_viewport().set_input_as_handled()
			elif _modal_touches.has(touch.index):
				var saved: Dictionary=_modal_touches[touch.index]
				_modal_touches.erase(touch.index)
				get_viewport().set_input_as_handled()
				if not touch.canceled and not saved.get("dragged",false) and is_instance_valid(saved["button"]) and not saved["button"].disabled and touch.position.distance_to(saved["pos"])<18:
					saved["button"].pressed.emit()
			return
		if not touch.pressed or touch.canceled:
			if _combat_touches.has(touch.index):
				_combat_touches.erase(touch.index)
				_refresh_attack_held()
				get_viewport().set_input_as_handled()
			return
		if not combat_enabled:
			return
		var id: String = _combat_action_at(touch.position)
		if not id.is_empty():
			_combat_touches[touch.index] = id
			_refresh_attack_held()
			get_viewport().set_input_as_handled()
			action.emit(id)
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if _modal.visible and _modal_touches.has(drag.index):
			var saved: Dictionary=_modal_touches[drag.index]
			if drag.position.distance_to(saved["pos"])>12: saved["dragged"]=true
			if saved["dragged"]: _modal_scroll.scroll_vertical=int(saved["scroll"]+saved["pos"].y-drag.position.y)
			get_viewport().set_input_as_handled()
			return
		if _combat_touches.has(drag.index):
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if not _mouse_combat_action.is_empty() or (motion.device == InputEvent.DEVICE_ID_EMULATION and (combat_enabled or _emulated_mouse_captured)):
			get_viewport().set_input_as_handled()


func _combat_action_at(viewport_position: Vector2) -> String:
	for key: Variant in _combat_buttons:
		var button: Button = _combat_buttons[key] as Button
		if not button.is_visible_in_tree() or button.disabled:
			continue
		var local: Vector2 = button.get_global_transform_with_canvas().affine_inverse() * viewport_position
		if Rect2(Vector2.ZERO, button.size).has_point(local):
			return str(key)
	return ""


func _refresh_attack_held() -> void:
	attack_held = _mouse_combat_action == "attack" or _combat_touches.values().has("attack")


func _reset_combat_input() -> void:
	attack_held = false
	_mouse_combat_action = ""
	_combat_touches.clear()
	move_vector = Vector2.ZERO
	if is_instance_valid(_joystick):
		_joystick.reset()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_reset_combat_input()


func _apply_safe_area() -> void:
	if not OS.has_feature("android") or not is_instance_valid(_root): return
	var safe: Rect2i=DisplayServer.get_display_safe_area()
	var physical: Vector2i=DisplayServer.screen_get_size()
	if physical.x<=0 or physical.y<=0 or safe.size.x<=0: return
	var logical: Vector2=get_viewport().get_visible_rect().size
	var ratio: Vector2=logical/Vector2(physical)
	_root.offset_left=maxf(0,safe.position.x*ratio.x)
	_root.offset_right=-maxf(0,(physical.x-safe.end.x)*ratio.x)
	_root.offset_top=maxf(0,safe.position.y*ratio.y)
	_root.offset_bottom=-maxf(0,(physical.y-safe.end.y)*ratio.y)
	_layout_modal()

func _layout_modal() -> void:
	if not is_instance_valid(_modal_panel):
		return
	var viewport_size: Vector2 = _root.size
	var panel_width: float = minf(940.0, maxf(280.0, viewport_size.x - 48.0))
	var panel_height: float = minf(644.0, maxf(280.0, viewport_size.y - 56.0))
	_modal_panel.position = (viewport_size - Vector2(panel_width, panel_height)) * 0.5
	_modal_panel.size = Vector2(panel_width, panel_height)
	_modal_grid.columns = 2 if _modal_buttons.size() >= 4 and panel_width >= 680.0 else 1
	_modal_title.add_theme_font_size_override("font_size", 37 if panel_width >= 680.0 else 29)
	var columns: int = _modal_grid.columns
	var card_width: float = (panel_width - 82.0 - float(columns - 1) * 13.0) / float(columns)
	var copy_width: float = maxf(80.0, card_width - 40.0)
	var font: Font = _root.get_theme_font("font", "Label")
	for child: Node in _modal_grid.get_children():
		var card: Button = child as Button
		if card == null:
			continue
		var title_text: String = str(card.get_meta("card_label", ""))
		var detail_text: String = str(card.get_meta("card_detail", ""))
		var title_height: float = font.get_multiline_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, copy_width, 21).y
		var detail_height: float = 0.0
		if not detail_text.is_empty():
			detail_height = font.get_multiline_string_size(detail_text, HORIZONTAL_ALIGNMENT_LEFT, copy_width, 15).y + 5.0
		card.custom_minimum_size.y = maxf(91.0, title_height + detail_height + 34.0)


func _on_stick_moved(value: Vector2) -> void:
	move_vector = value


func _hide_toast() -> void:
	_toast_panel.hide()


func _button(text: String, id: String, minimum: Vector2) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = minimum
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(_emit_action.bind(id))
	return button


func _emit_action(id: String) -> void:
	action.emit(id)


func _label(text: String, font_size: int, color: Color) -> Label:
	var result: Label = Label.new()
	result.text = text
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	return result


func _bar(color: Color, height: float) -> ProgressBar:
	var result: ProgressBar = ProgressBar.new()
	result.custom_minimum_size = Vector2(0, height)
	result.show_percentage = false
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_stylebox_override("background", _box(Color("ccc9bb"), Color.TRANSPARENT, 2, 0))
	result.add_theme_stylebox_override("fill", _box(color, Color.TRANSPARENT, 2, 0))
	return result


func _margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var result: MarginContainer = MarginContainer.new()
	result.add_theme_constant_override("margin_left", left)
	result.add_theme_constant_override("margin_top", top)
	result.add_theme_constant_override("margin_right", right)
	result.add_theme_constant_override("margin_bottom", bottom)
	return result


func _box(background: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var result: StyleBoxFlat = StyleBoxFlat.new()
	result.bg_color = background
	result.border_color = border
	result.set_border_width_all(border_width)
	result.set_corner_radius_all(radius)
	return result


func _round_button(caption: String,id: String,icon: String,diameter: float,tint: Color) -> Button:
	var button: Button=_button("",id,Vector2(diameter,diameter))
	button.size=Vector2(diameter,diameter)
	for state_name in ["normal","hover","pressed","disabled"]:
		var color: Color=Color(0.10,0.16,0.15,0.86) if state_name!="pressed" else Color(0.30,0.38,0.31,0.96)
		button.add_theme_stylebox_override(state_name,_box(color,tint,int(diameter/2),2))
	var glyph:=TextureRect.new()
	glyph.texture=load("res://assets/ui/"+icon+".svg")
	glyph.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.position=Vector2(diameter*0.27,diameter*0.12)
	glyph.size=Vector2(diameter*0.46,diameter*0.46)
	glyph.mouse_filter=Control.MOUSE_FILTER_IGNORE
	button.add_child(glyph)
	button.set_meta("glyph",glyph)
	var label: Label=_label(caption,16,Color("f4e8cc"))
	label.position=Vector2(4,diameter*0.62)
	label.size=Vector2(diameter-8,24)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	button.set_meta("caption",label)
	var cooldown: Label=_label("",18,Color("fff2d5"))
	cooldown.position=Vector2(3,diameter*0.28)
	cooldown.size=Vector2(diameter-6,25)
	cooldown.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	cooldown.add_theme_color_override("font_shadow_color",Color.BLACK)
	cooldown.add_theme_constant_override("shadow_offset_x",2)
	cooldown.add_theme_constant_override("shadow_offset_y",2)
	cooldown.mouse_filter=Control.MOUSE_FILTER_IGNORE
	button.add_child(cooldown)
	button.set_meta("cooldown",cooldown)
	return button

func _ability_caption(button: Button,value: String) -> void:
	var label: Label=button.get_meta("caption")
	label.text=value

func _audio_touch_value(slider: HSlider, point: Vector2) -> void:
	var rect: Rect2=slider.get_global_rect()
	slider.value=clampf((point.x-rect.position.x)/rect.size.x,0,1)*100

func show_audio(music: float, sfx: float) -> void:
	show_modal("声音设置","音乐与音效分别调节；拖至 0 可单独静音。",[{"id":"audio_back","label":"保存并返回"}],"声音")
	for child in _audio_controls.get_children():
		_audio_controls.remove_child(child)
		child.queue_free()
	_audio_sliders.clear()
	for channel in ["music","sfx"]:
		var title: String="背景音乐" if channel=="music" else "游戏音效"
		var value: float=music if channel=="music" else sfx
		var label: Label=_label(title+"  %d%%"%roundi(value*100),22,Color("42493f"))
		_audio_controls.add_child(label)
		var slider:=HSlider.new()
		slider.min_value=0
		slider.max_value=100
		slider.step=1
		slider.value=value*100
		slider.custom_minimum_size=Vector2(240,52)
		_audio_controls.add_child(slider)
		_audio_sliders[channel]=slider
		slider.value_changed.connect(func(v: float):
			label.text=title+"  %d%%"%roundi(v)
			volume_changed.emit(channel,v/100.0))
	_audio_controls.show()
