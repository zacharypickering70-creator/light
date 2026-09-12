extends RefCounted

const Techniques = preload("res://scripts/techniques.gd")

static func populate(g: Node) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = g.map_seed + 8173
	var available: Array = Techniques.SKILLS.keys()
	for index in [1, 3, 5]:
		var center: Vector3 = g.world.landmarks[index]["pos"]
		var angle: float = random.randf_range(0, TAU)
		var position: Vector3 = g.world.constrain_position(center + Vector3(cos(angle), 0, sin(angle)) * 6.0)
		g._add_pickup("scroll", position, index)
		var pickup: Dictionary = g.pickups.back()
		pickup["skill"] = available.pop_at(random.randi_range(0, available.size() - 1))
		set_title(pickup, "武学遗卷 · " + Techniques.SKILLS[pickup["skill"]]["name"])
	for pickup in g.pickups:
		if pickup["kind"] == "chest" and pickup["id"] in [2, 4]:
			pickup["kind"] = "supply"
			set_title(pickup, "行旅补给箱")

static func set_title(pickup: Dictionary, text: String) -> void:
	var label: Label3D = pickup["node"].get_node("InteractionTitle")
	label.text = text
	label.visibility_range_end = 0
	label.get_node("InkNameplate").free()
	preload("res://scripts/world_label.gd").finish(label)

static func update_labels(g: Node) -> void:
	for pickup in g.pickups:
		if pickup["kind"] in ["scroll", "supply"] and not pickup["used"]:
			pickup["node"].get_node("InteractionTitle").visible = g.player.position.distance_to(pickup["pos"]) <= 14.0

static func show_scroll(g: Node, pickup: Dictionary) -> void:
	g.found_scroll = pickup
	g.state = "found_skill"
	var skill: String = pickup["skill"]
	var buttons: Array = []
	if skill in g.learned_skills:
		var rank: int = g.skill_ranks.get(skill, 1)
		buttons.append({"id":"scroll_upgrade", "label":"参悟同门招式", "detail":"此招提升 1 级" if rank < 5 else "此招已满级，获得 1 学习点"})
	else:
		for slot in range(g._skill_capacity()):
			if slot > g.learned_skills.size(): break
			var detail: String = "学入第 %d 招" % (slot + 1)
			if slot < g.learned_skills.size(): detail = "替换 " + Techniques.SKILLS[g.learned_skills[slot]]["name"] + "，新招从 1 级开始"
			buttons.append({"id":"scroll_slot_%d" % slot, "label":detail, "detail":"消耗遗卷，不消耗学习点"})
	buttons.append({"id":"scroll_leave", "label":"留在原处"})
	g.ui.show_modal("拾得 · " + Techniques.SKILLS[skill]["name"], Techniques.SKILLS[skill]["desc"] + "\n仅本次闯关生效。第二、三招仍在修为 3、5 时开放。", buttons, "散落武学 · 自由搭配")

static func handle(g: Node, id: String) -> bool:
	if g.state != "found_skill": return false
	if id == "scroll_leave":
		g.found_scroll = {}
		g.state = "playing"
		g.ui.hide_modal()
		return true
	var pickup: Dictionary = g.found_scroll
	if pickup.is_empty() or pickup["used"]: return true
	var skill: String = pickup["skill"]
	if id == "scroll_upgrade" and skill in g.learned_skills:
		if g.skill_ranks.get(skill, 1) < 5: g.skill_ranks[skill] = int(g.skill_ranks.get(skill, 1)) + 1
		else: g.study_points += 1
	elif id.begins_with("scroll_slot_") and skill not in g.learned_skills:
		var slot: int = int(id.trim_prefix("scroll_slot_"))
		if slot < 0 or slot >= g._skill_capacity() or slot > g.learned_skills.size(): return true
		if slot < g.learned_skills.size():
			g.skill_ranks.erase(g.learned_skills[slot])
			g.learned_skills[slot] = skill
		else: g.learned_skills.append(skill)
		g.skill_ranks[skill] = 1
		g.skill_cds[slot] = maxf(g.skill_cds[slot], 0.5)
		g.active_skill = skill
	else: return true
	pickup["used"] = true
	pickup["node"].hide()
	g.found_scroll = {}
	g.state = "playing"
	g.ui.hide_modal()
	g._queue_feedback("参悟 · " + Techniques.SKILLS[skill]["name"], Color(Techniques.SKILLS[skill]["color"]))
	return true

static func decorate(g: Node, node: Node3D, kind: String) -> void:
	if kind not in ["scroll", "chest"]: return
	for index in range(3):
		var part := MeshInstance3D.new()
		var box := BoxMesh.new()
		if kind == "scroll":
			box.size = Vector3(0.85, 0.10, 0.5) if index == 0 else Vector3(0.12, 0.16, 0.65)
			part.position = Vector3(0 if index == 0 else (-0.43 if index == 1 else 0.43), 0.55, 0)
		else:
			box.size = Vector3(0.9, 0.12, 0.65) if index == 0 else Vector3(0.09, 0.65, 0.58)
			part.position = Vector3(0 if index == 0 else (-0.27 if index == 1 else 0.27), 0.7 if index == 0 else 0.38, 0)
		part.mesh = box
		part.material_override = g._material(Color("e9d7a7") if kind == "scroll" and index == 0 else Color("9b7643"))
		node.add_child(part)
