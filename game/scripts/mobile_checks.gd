extends RefCounted

static func run(g: Node) -> void:
	var failures: Array[String]=[]
	var tech=load("res://scripts/techniques.gd")
	if tech.SKILLS.size()<12 or tech.ULTIMATES.size()<10 or tech.MINDS.size()<10 or g.BOONS.size()<32: failures.append("catalog counts")
	var seeds: Dictionary={}
	for seed_value in range(1,101):
		var layout=g.world.generate_layout(seed_value)
		if layout.size()!=7 or str(layout)!=str(g.world.generate_layout(seed_value)): failures.append("map determinism")
		seeds[str(layout)]=true
	if seeds.size()<95: failures.append("map diversity")
	g._start_run()
	g._on_action("begin")
	for i in range(100): g._tick_game(0.03)
	if g.journey_started or g.enemies.size()!=0 or g.run_seconds!=0 or g.world.landmarks.size()!=1: failures.append("independent safe home")
	# Input must remain live through an impact; short early taps must execute once.
	g.ui.move_vector=Vector2.RIGHT
	g.hit_stop=0.05
	var before: Vector3=g.player.position
	g._tick_game(0.016)
	if g.player.position.x<=before.x: failures.append("movement during impact")
	if absf(g.player.get_node("Body/LeftLeg").rotation.x)<0.001: failures.append("walk articulation")
	g.ui.move_vector=Vector2.ZERO
	g.attack_cd=0.08
	g.combo=0
	g._on_action("attack")
	for i in range(7): g._tick_game(0.016)
	if g.combo!=1: failures.append("buffered attack executes once")
	var enemy=g._spawn_enemy("grunt",g.player.position+Vector3(2,0,0))
	g._damage_enemy(enemy,1,g.player.position)
	if enemy["node"].get_node("Body").rotation.x>=0: failures.append("enemy recoil")
	g.attack_cd=0
	g._attack()
	var aim: Vector3=g.facing
	g.ui.move_vector=Vector2.LEFT
	g._tick_game(0.016)
	if g.facing.dot(aim)<0.99: failures.append("attack facing preserved while moving")
	g._dash(Vector3.LEFT)
	if g.hit_stop>0 or g.dash_left<=0: failures.append("dash cancels impact")
	g._start_run()
	g._on_action("begin")
	g.player.position=Vector3(18,0,0)
	g._tick_game(0.03)
	if g.journey_started: failures.append("walking cannot start combat")
	g._on_action("weapons")
	g._on_action("equip_long_spear")
	g._on_action("resume")
	if g.progress["equipped"]["blade"]!="long_spear": failures.append("direct weapon pickup")
	g._on_action("techniques")
	g._on_action("arts")
	g._on_action("choose_arts_sweep")
	g._on_action("resume")
	if g.normal_art!="sweep": failures.append("independent attack art")
	g._show_learning(0)
	g._learn_skill("frost")
	g._on_action("resume")
	if g.learned_skills!=["frost"]: failures.append("first lesson")
	g.player.position=Vector3(8,0,4)
	g._interact()
	if not g.journey_started or g.world.landmarks.size()!=7 or g.progress["equipped"]["blade"]!="long_spear" or g.learned_skills!=["frost"]: failures.append("portal carries prepared loadout into new map")
	g.world.landmarks[6]["visited"]=true
	if g._visible_map_points().size()!=1: failures.append("unspawned boss hidden")
	g._tick_waves(1.0)
	if g.enemies.size()<7: failures.append("combat waves")
	g._test_clear_enemies()
	g.level=3
	g.study_points=3
	g._show_learning(1)
	g._learn_skill("thunder")
	if g.study_points!=2 or g.learned_skills.size()!=2: failures.append("one lesson one point")
	g._show_learning(1)
	g._on_action("rank_skill")
	if g.skill_ranks["thunder"]!=2 or g.study_points!=1: failures.append("single skill upgrade")
	g._show_learning(1)
	g._learn_skill("barrier")
	if g.learned_skills!=["frost","barrier"] or g.study_points!=0 or g.skill_ranks.has("thunder"): failures.append("single skill replacement resets rank")
	g._on_action("resume")
	g._show_learning(2)
	if g.state=="learning": failures.append("third skill level gate")
	g.level=5
	g.study_points=1
	g._show_learning(2)
	g._learn_skill("fire")
	g._on_action("resume")
	if g.learned_skills.size()!=3: failures.append("three equipped skills")
	g.energy=100
	g.skill_cds.assign([0.0,0.0,0.0])
	g._cast_skill(0)
	g._cast_skill(1)
	g._cast_skill(2)
	if g.skill_cds.filter(func(v):return v>0).size()!=3: failures.append("independent skill cooldowns")
	# Every skill must perform its advertised kind of action, not just change its label.
	for id in tech.SKILLS:
		g._test_clear_enemies()
		g.state="playing"
		g.player.position=Vector3(0,0,9)
		g.learned_skills.assign([id])
		g.skill_ranks={id:1}
		g.skill_cds.assign([0.0,0.0,0.0])
		g.energy=100
		g.hp=60
		g.shield_hp=0
		g.guard_left=0
		g.haste_left=0
		var target=g._spawn_enemy("brute",g.player.position+Vector3(0,0,-3))
		target["hp"]=2000.0
		target["max_hp"]=2000.0
		g._cast_skill(0)
		if g.energy>=100 or g.skill_cds[0]<=0: failures.append(id+" resource")
		if id=="heal":
			if g.hp<=60: failures.append("healing")
		elif id=="barrier":
			if g.shield_hp<=0 or g.guard_left<=0: failures.append("shield")
		elif id=="haste":
			if g.haste_left<=0: failures.append("haste")
		elif target["hp"]>=2000: failures.append(id+" hit")
		if id=="frost" and target["slow"]<=0: failures.append("slow")
		if id=="poison" and target["poison"]<=0: failures.append("poison")
		if id=="weak" and target["weak"]<=0: failures.append("weak")
		if id=="stun" and target["stun"]<=0: failures.append("stun")
		if id=="vortex" and target["node"].position.distance_to(g.player.position)>2.1: failures.append("pull")
		if id=="quake" and target["node"].position.distance_to(g.player.position)<5.5: failures.append("knockback")
		await g.get_tree().process_frame
	for id in tech.ULTIMATES:
		g._test_clear_enemies()
		g.state="playing"
		g.hp=60
		g.shield_hp=0
		g.avatar_left=0
		g.ultimate_id=id
		g.ultimate_charge=100
		g.ultimate_cd=0
		var target=g._spawn_enemy("brute",g.player.position+Vector3(0,0,-3))
		target["hp"]=2000.0
		target["max_hp"]=2000.0
		g._ultimate()
		if g.ultimate_charge!=0: failures.append(id+" charge")
		if id=="avatar":
			if g.avatar_left<=0: failures.append("avatar buff")
		elif target["hp"]>=2000: failures.append(id+" ultimate effect")
		if id=="sanctuary" and (g.hp<=60 or g.shield_hp<=0): failures.append("sanctuary recovery")
		await g.get_tree().process_frame
	# Test that the same attacks and spells work across every weapon.
	g.boon_counts.clear()
	g.passives.clear()
	g.momentum_left=0
	g.avatar_left=0
	g.haste_left=0
	for weapon in load("res://scripts/arsenal.gd").WEAPONS:
		for art in tech.ARTS:
			g._test_clear_enemies()
			g.state="playing"
			g.progress["equipped"]["blade"]=weapon
			g.normal_art=art
			g.attack_cd=0
			g.combo=0
			var target=g._spawn_enemy("brute",g.player.position+Vector3(0,0,-2))
			target["hp"]=2000.0
			var rear=g._spawn_enemy("brute",g.player.position+Vector3(0,0,2.2))
			rear["hp"]=2000.0
			g._attack()
			if target["hp"]>=2000: failures.append(weapon+" "+art)
			if (rear["hp"]<2000)!=(art=="sweep"): failures.append("art shape "+weapon+" "+art)
	g._test_clear_enemies()
	g.passives.assign(["reservoir"])
	g.energy=40
	g._tick_buffs(1)
	if g.energy!=42: failures.append("reservoir mind")
	g.passives.assign(["ironwall"])
	g.shield_hp=0
	g.guard_left=0
	g.immunity=0
	g.hp=100
	g._hurt_player(20)
	if absf(g.hp-83)>0.1: failures.append("ironwall mind")
	g.passives.assign(["momentum"])
	g.momentum_left=0
	var base=g._base_damage()
	g.dash_cd=0
	g._dash(Vector3.RIGHT)
	if g._base_damage()<base*1.34: failures.append("momentum mind")
	g.dash_left=0
	for mind in ["leech","merciful"]:
		g.passives.assign([mind])
		g.hp=60
		g.shield_hp=0
		var target=g._spawn_enemy("grunt",g.player.position+Vector3(0,0,-2))
		g._damage_enemy(target,10000,g.player.position)
		if mind=="leech" and g.hp!=62: failures.append("leech mind")
		if mind=="merciful" and g.shield_hp!=2: failures.append("merciful mind")
	g.passives.assign(["focus"])
	g.learned_skills.assign(["fire"])
	g.skill_cds.assign([0.0,0.0,0.0])
	g.energy=100
	g._cast_skill(0)
	if absf(g.skill_cds[0]-4.5)>0.01: failures.append("focus mind")
	g._test_clear_enemies()
	g.passives.assign(["orbit"])
	g.orbit_clock=0
	var target=g._spawn_enemy("brute",g.player.position+Vector3(0,0,2.3))
	var health=target["hp"]
	g.run_seconds=0
	g._tick_orbit(0.1)
	if target["hp"]>=health: failures.append("orbit mind")
	g._test_clear_enemies()
	g.passives.assign(["spark"])
	g.normal_art="thrust"
	g.spark_hits=0
	g.momentum_left=0
	target=g._spawn_enemy("brute",g.player.position+Vector3(0,0,-2))
	target["hp"]=2000.0
	var rear=g._spawn_enemy("brute",g.player.position+Vector3(0,0,2))
	rear["hp"]=2000.0
	for i in range(3):
		g.attack_cd=0
		g._attack()
	if rear["hp"]>=2000: failures.append("spark mind chain")
	g._test_clear_enemies()
	g.passives.clear()
	g.player.position=Vector3(0,0,9)
	g.ui.move_vector=Vector2.RIGHT
	g.wave_clock=100
	g.pending_levels=0
	g.hit_stop=0
	g._tick_game(0.04)
	var normal_move=g.player.position.x
	g.player.position=Vector3(0,0,9)
	g.passives.assign(["swift"])
	g._tick_game(0.04)
	if g.player.position.x<normal_move*1.08: failures.append("swift mind")
	g.ui.move_vector=Vector2.ZERO
	g.passives.assign(["fury"])
	g.normal_art="cleave"
	g.combo=0
	g.attack_cd=0
	target=g._spawn_enemy("brute",g.player.position+Vector3(0,0,-2))
	target["hp"]=2000.0
	for seed_value in range(1,100):
		g.rng.seed=seed_value
		if g.rng.randf()<0.12:
			g.rng.seed=seed_value
			break
	base=g._base_damage()
	g._attack()
	if 2000-target["hp"]<base*1.79: failures.append("fury mind crit")
	g._test_clear_enemies()
	g.run_seconds=360
	g._tick_waves(0)
	if not g.boss_spawned: failures.append("timed boss")
	var boss_count=g.enemies.filter(func(e):return e["kind"]=="boss").size()
	g._spawn_boss()
	if boss_count!=1 or g.enemies.filter(func(e):return e["kind"]=="boss").size()!=1: failures.append("single boss")
	g._test_clear_enemies()
	g.boon_counts["shield"]=2
	g.shield_clock=0
	g.shield_hp=0
	g._tick_buffs(0.1)
	if g.shield_hp!=20: failures.append("periodic shield boon")
	g.kills=12
	var coins=g.legacy["coins"]
	g._finish_run(false)
	var after=g.legacy["coins"]
	g._finish_run(false)
	if after<=coins or g.legacy["coins"]!=after: failures.append("settlement once")
	if g.journey_started or g.enemies.size()!=0 or g.world.landmarks.size()!=1 or not g.learned_skills.is_empty() or not g.skill_ranks.is_empty() or not g.boon_counts.is_empty(): failures.append("death returns safe home and clears all run skills")
	g._on_action("back_home")
	g.state="equipment"
	g._on_action("legacy")
	g._on_action("legacy_heart")
	var saved_coins=g.legacy["coins"]
	var path="user://mobile04-validation.json"
	g._save_legacy(path)
	g.legacy={"coins":0,"heart":0,"weapon":0,"spirit":0}
	g._load_legacy(path)
	if g.legacy["heart"]!=1 or g.legacy["coins"]!=saved_coins: failures.append("legacy disk roundtrip")
	DirAccess.remove_absolute(path)
	# Independent audio buses and preference persistence.
	g._set_volume("music",0)
	g._set_volume("sfx",0.63)
	if not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")) or AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")): failures.append("independent audio mute")
	var audio_path="user://audio-validation.cfg"
	g._save_audio(audio_path)
	g.music_volume=1
	g.sfx_volume=1
	g._load_audio(audio_path)
	if g.music_volume!=0 or absf(g.sfx_volume-0.63)>0.001: failures.append("audio preference persistence")
	DirAccess.remove_absolute(audio_path)
	if not g.music_player.stream.loop or g.music_player.stream.get_length()<55: failures.append("music looping asset")
	g._set_volume("music",0.35)
	g._start_run()
	g._on_action("begin")
	g._show_learning(0)
	g._learn_skill("fire")
	g._on_action("resume")
	g.chapter=1
	g._start_expedition()
	g.kills=1
	g._finish_run(true)
	if g.legacy.get("chapter",1)!=2: failures.append("chapter two unlock")
	g._save_legacy(path)
	g.legacy["chapter"]=1
	g._load_legacy(path)
	DirAccess.remove_absolute(path)
	if g.legacy.get("chapter",1)!=2: failures.append("chapter unlock persistence")
	g._on_action("back_home")
	g._show_learning(0)
	g._learn_skill("fire")
	g._on_action("resume")
	g._depart()
	if g.state!="chapters": failures.append("chapter selection portal")
	g._on_action("chapter_2")
	g._on_action("begin")
	if g.chapter!=2 or g.world.landmarks[6]["name"]!="听愿正殿": failures.append("chapter two map")
	var rescue_count: int=0
	for pickup in g.pickups:
		if pickup["kind"]=="rescue":
			rescue_count+=1
			g.player.position=pickup["pos"]
			g._interact()
			g._on_action("begin")
	if rescue_count!=2 or g.rescued!=2 or g.study_points!=2: failures.append("rescue rewards")
	g._spawn_boss()
	var shrine_boss: Dictionary=g.enemies.back()
	g._telegraph(shrine_boss)
	if shrine_boss["attack"]!="blessing": failures.append("shrine boss distinct attack")
	g._resolve_enemy_attack(shrine_boss)
	g.player.position=g.blessings[0]["pos"]
	g.hp=50
	g._tick_blessings(2.1)
	if g.hp<=50 or g.blessing_exposure<2: failures.append("blessing heals and binds")
	g.player.position+=Vector3(8,0,0)
	g._tick_blessings(0.1)
	if g.blessing_exposure!=0: failures.append("leave blessing releases binding")
	g._damage_enemy(shrine_boss,100000,g.player.position)
	if not g.last_result.get("victory",false) or g.last_result.get("chapter",0)!=2 or g.journey_started or not g.blessings.is_empty(): failures.append("chapter two victory returns home")
	var store=load("res://scripts/profile_store.gd")
	var store_path="user://profile06-test.json"
	var first: Dictionary={"coins":123,"heart":2,"weapon":1,"spirit":0,"chapter":2}
	if store.save_profile(first,store_path)!=OK: failures.append("profile first save")
	var second: Dictionary=first.duplicate()
	second["coins"]=234
	if store.save_profile(second,store_path)!=OK or store.load_profile(store_path)["coins"]!=234: failures.append("profile atomic replace")
	var broken:=FileAccess.open(store_path,FileAccess.WRITE)
	broken.store_string("{broken")
	broken.close()
	if store.load_profile(store_path)["coins"]!=123: failures.append("profile backup recovery")
	var cleaned: Dictionary=store.sanitize({"coins":{},"heart":"bad","chapter":99,"weapon":-5})
	if cleaned["coins"]!=30 or cleaned["heart"]!=0 or cleaned["chapter"]!=2 or cleaned["weapon"]!=0: failures.append("profile malformed values")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(store_path+suffix): DirAccess.remove_absolute(store_path+suffix)
	# Defeating a boss in a chained explosion must not resume the outer kill in the new home.
	g.chapter=1
	g._start_run()
	g._on_action("begin")
	g._start_expedition()
	g.normal_art="cleave"
	var chain_mob: Dictionary=g._spawn_enemy("grunt",g.player.position+Vector3(2,0,0))
	chain_mob["burn"]=3.0
	var chain_boss: Dictionary=g._spawn_enemy("boss",g.player.position+Vector3(2.5,0,0))
	chain_boss["hp"]=1
	g._damage_enemy(chain_mob,1000,g.player.position)
	if g.state!="result" or g.kills!=0 or g.xp!=0 or g.eruption_depth!=0: failures.append("chain victory transaction cleanup")
	g.chapter=2
	g._start_expedition()
	g._on_action("begin")
	var archer: Dictionary=g._spawn_enemy("ranger",g.player.position+Vector3(8,0,0))
	archer["weak"]=5.0
	archer["power"]=2.0
	g._telegraph(archer)
	g._resolve_enemy_attack(archer)
	if g.projectiles.size()!=3: failures.append("chapter two fan count")
	elif absf(g.projectiles[0]["damage"]-18)>0.01 or absf(g.projectiles[1]["damage"]-13.5)>0.01: failures.append("weakness applies to all fan projectiles")
	g._clear_projectiles()
	g.hp=1
	g.immunity=0
	g.shield_hp=0
	g.boon_counts.clear()
	g._spawn_projectile(g.player.position,Vector3.ZERO,0,1000)
	g._tick_projectiles(0.01)
	if g.state!="result" or g.journey_started: failures.append("fatal projectile safe cleanup")
	await g.get_tree().process_frame
	if failures.is_empty():
		print("MOBILE_05_PASS: audio buses/save/loop, chapter unlock/portal/rescue/boss/blessing/ending, independent home and portal, direct weapon selection, 3 learning slots/upgrade/replacement, 12 skills, 10 ultimates, 10 minds, 20 weapon-art pairs, randomized maps, death reset, persistent roots")
		g.get_tree().quit(0)
	else:
		for failure in failures: push_error("MOBILE04_FAILED: "+failure)
		g.get_tree().quit(1)
