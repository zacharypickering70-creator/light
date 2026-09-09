extends RefCounted
static func run(g: Node) -> void:
	var failures: Array[String]=[]
	g.set_process(false)
	g._start_run()
	g._on_action("begin")
	if g.progress["owned"]["robe"].size()!=6 or g.progress["owned"]["lamp"].size()!=6: failures.append("six equipment choices")
	for robe in g.Arsenal.ROBES:
		g.progress["equipped"]["robe"]=robe
		for lamp in g.Arsenal.LAMPS:
			g.progress["equipped"]["lamp"]=lamp
			g._refresh_gear_visual()
			if g.player.get_node_or_null("LoadoutAura/SpiritOrb")==null: failures.append("floating orb")
	g.progress["equipped"]["robe"]="sage_robe"
	g.progress["equipped"]["lamp"]="frost_lamp"
	g._show_learning(0)
	g._learn_skill("fire")
	g._on_action("resume")
	g.chapter=1
	g._start_expedition()
	if g.progress["equipped"]["robe"]!="sage_robe" or g.progress["equipped"]["lamp"]!="frost_lamp": failures.append("starting loadout retained")
	for pickup in g.pickups:
		if pickup["kind"] in ["forge","manual","rack"]: failures.append("no combat preparation stations")
	var before: Dictionary=g.progress.duplicate(true)
	g._on_action("equip_iron_robe")
	g._on_action("upgrade_blade")
	if g.progress!=before: failures.append("locked combat loadout")
	var prev: int=0
	for lv in range(1,30):
		var needed: int=g._xp_requirement(lv)
		if needed<=prev: failures.append("increasing experience curve")
		prev=needed
	g._tick_waves(0.5)
	var first_power: float=g.enemies.back()["power"]
	if g.enemies.size()!=14: failures.append("50 percent additional first wave")
	g.wave_clock=0
	g._tick_waves(0.01)
	var last_power: float=g.enemies.back()["power"]
	if absf(last_power/first_power-1.035)>0.0001: failures.append("3.5 percent wave growth")
	g.hp=63
	g.energy=47
	g.level=7
	g.xp=23
	g.xp_next=g._xp_requirement(7)
	g.skill_ranks["fire"]=3
	g.boon_counts["edge"]=2
	g.ultimate_charge=61
	g.skill_cds.assign([2.0,0.0,0.0])
	g.progress["gear"]["blade"]=2
	g.kills=20
	g._finish_run(true)
	if g.state!="transition" or not g.journey_started: failures.append("clear presents choice")
	g._on_action("continue_stage")
	if g.stage_depth!=2 or g.chapter!=2 or g.hp!=63 or g.energy!=47 or g.xp!=23 or g.level!=7 or g.skill_ranks["fire"]!=3 or g.boon_counts["edge"]!=2 or g.progress["gear"]["blade"]!=2 or g.ultimate_charge!=61 or g.skill_cds[0]!=2: failures.append("complete cross-stage state preservation")
	if g.boss_spawned or g.stage_entry_level!=7: failures.append("fresh stage boss threshold")
	g.wave_clock=0
	g._tick_waves(0.01)
	if g.enemies.back()["power"]<=last_power: failures.append("new stage first wave stronger than last")
	g._finish_run(true)
	g._on_action("continue_stage")
	if g.stage_depth!=3 or g.hp!=63: failures.append("second clear keeps campaign")
	g._finish_run(true)
	var coins: int=g.legacy["coins"]
	var full: int=g.earned_incense+mini(g.kills/4,150)
	g._on_action("cash_out")
	if g.legacy["coins"]!=coins+full or g.journey_started: failures.append("voluntary home full reward")
	g._on_action("cash_out")
	if g.legacy["coins"]!=coins+full: failures.append("cash out once")
	g._on_action("back_home")
	g._show_learning(0)
	g._learn_skill("fire")
	g._on_action("resume")
	g._start_expedition()
	g.kills=20
	g.earned_incense=35
	coins=g.legacy["coins"]
	g._finish_run(false)
	if g.state!="dying" or not g.journey_started: failures.append("death animation state")
	await g.get_tree().create_timer(1.9).timeout
	if g.state!="result" or g.journey_started or not g.learned_skills.is_empty() or not g.boon_counts.is_empty() or g.legacy["coins"]!=coins+20: failures.append("death half rewards and reset")
	g._complete_death()
	if g.legacy["coins"]!=coins+20: failures.append("death settles once")
	if failures.is_empty():
		print("CAMPAIGN07_PASS: 36 loadouts, floating orb, increasing XP and waves, locks, preserved transitions, continue/cashout choice, death animation and half penalty")
		g.get_tree().quit(0)
	else:
		for failure in failures: push_error(failure)
		g.get_tree().quit(1)
