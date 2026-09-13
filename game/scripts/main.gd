extends Node3D

const Exploration = preload("res://scripts/exploration.gd")
var found_scroll: Dictionary = {}
var damage_sources: Dictionary = {}
var last_damage_source: String = ""

const ChapterSix=preload("res://scripts/chapter_six.gd")
const ChapterFive=preload("res://scripts/chapter_five.gd")
const ChapterFour=preload("res://scripts/chapter_four.gd")
const ChapterThree=preload("res://scripts/chapter_three.gd")
const ProfileStore=preload("res://scripts/profile_store.gd")
const WorldArt = preload("res://scripts/open_world.gd")
const GameUI = preload("res://scripts/game_ui.gd")
const Arsenal = preload("res://scripts/arsenal.gd")
const Techniques = preload("res://scripts/techniques.gd")
const GEAR_NAMES = Arsenal.NAMES
const SLOT_NAMES = {"blade":"兵刃", "robe":"衣甲", "lamp":"灵珠"}
const BASE_BOONS = [
{"id":"edge", "name":"锋火", "desc":"兵器伤害 +20%。适用于全部普攻套路。"},
{"id":"reach", "name":"长明", "desc":"普攻范围 +20%，更易命中成群敌人。"},
{"id":"quick", "name":"疾雨", "desc":"攻击间隔缩短 12%。"},
{"id":"flame", "name":"燎原", "desc":"伤害技能基础伤害 +35%，技能范围 +10%。"},
{"id":"drain", "name":"归火", "desc":"每次击败敌人回复 4 点生命。"},
{"id":"dash", "name":"踏莲", "desc":"踏影冷却缩短 18%，闪避也会伤到沿途敌人。"},
{"id":"health", "name":"生息", "desc":"生命上限 +22，并立即回复 35 点。"},
{"id":"energy", "name":"薪火", "desc":"每次命中额外获得 3 点灯火。"},
{"id":"ward", "name":"金身", "desc":"受到的伤害降低 14%。"},
{"id":"orbit", "name":"灯珠", "desc":"装备护灯时环绕伤害 +6。未装备时也会获得两枚较弱灯珠。"},
{"id":"burn", "name":"焚墨", "desc":"灼烧每秒伤害 +8；任何技能都能点燃敌人。"},
{"id":"echo", "name":"回响", "desc":"第三次普攻额外震击周围敌人，每层造成 10 伤害。"}
]

var BOONS: Array = BASE_BOONS + Techniques.EXTRA_BOONS
var world: Node3D
var ui: CanvasLayer
var progress: Dictionary
var actors: Node3D
var effects: Node3D
var gates: Node3D
var player: Node3D
var camera: Camera3D
var enemies: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var state: String = "camp"
var room_index: int = 0
var hp: float = 100.0
var max_hp: float = 100.0
var energy: float = 40.0
var xp: int = 0
const XP_STEPS: Array[int]=[40,85,160,260,380,520]
var xp_next: int = 40
var level: int = 1
var pending_levels: int = 0
var run_ash: int = 0
var run_gear: Array[String] = []
var attack_cd: float = 0.0
var dash_cd: float = 0.0
var flame_cd: float = 0.0
var dash_left: float = 0.0
var immunity: float = 0.0
var hit_stop: float = 0.0
var attack_buffer: float = 0.0
var attack_pose_duration: float = 0.20
var cast_pose: float = 0.0
var queued_skill: int = -1
var skill_buffer: float = 0.0
var dash_buffer: float = 0.0
var buffered_dash_direction := Vector3.ZERO
var attack_pose: float = 0.0
var weapon_tween: Tween
var pose_time: float = 0.0
var facing: Vector3 = Vector3.FORWARD
var dash_dir: Vector3 = Vector3.FORWARD
var walk_time: float = 0.0
var combo: int = 0
var combo_time: float = 0.0
var boon_counts: Dictionary = {}
var choices: Array[Dictionary] = []
var choice_serial: int = 0
var rng := RandomNumberGenerator.new()
var test_mode: bool = false
var wave_density: float = 1.3
var swarm_multiplier: float=1.5
var wave_growth: float=1.035
var received_hits: int = 0
var received_damage: float = 0.0
var capture_mode: bool = false
var start_time: float = 0.0
var map_seed: int = 0
var pickups: Array[Dictionary] = []
var story_found: Array[int] = []
var boss_introduced: bool = false
var kills: int = 0
var run_seconds: float = 0.0
var wave_clock: float = 0.0
var wave_number: int = 0
var boss_spawned: bool = false
var orbit_clock: float = 0.0
var muted: bool = false
var music_player: AudioStreamPlayer
var music_volume: float=0.35
var sfx_volume: float=0.85
var audio_return: String="paused"
var chapter: int=1
var stage_depth: int=1
var stage_seconds: float=0
var stage_entry_level: int=1
var earned_incense: int=0
var death_serial: int=0
var blessings: Array[Dictionary]=[]
var blessing_exposure: float=0
var rooted_left: float=0
var root_ward: float=0
var root_mark: Label3D
var rescued: int=0
var remembered: int=0
var released_memories: int=0
var memory_id: int=-1
var final_voices: Array[int]=[]
var ending_choice: String=""
var restored_names: int=0
var anchored_lights: int=0
var last_cast: String="fire"
var varied_cast: bool=false
var last_words_index: int=0
var words_tween: Tween
var quality: String = "balanced"
var sound_player: AudioStreamPlayer
var active_skill: String = "fire"
var learned_skills: Array[String] = []
var skill_ranks: Dictionary = {}
var skill_cds: Array[float] = [0.0,0.0,0.0]
var study_points: int = 0
var learning_slot: int = 0
var level_learning: bool=false
var normal_art: String = "cleave"
var ultimate_id: String = "lotus"
var ultimate_charge: float = 0.0
var ultimate_cd: float = 0.0
var shield_hp: float = 0.0
var shield_clock: float = 0.0
var guard_left: float = 0.0
var haste_left: float = 0.0
var avatar_left: float = 0.0
var selected_weapon: String = "ferry_blade"
var settled: bool = false
var last_result: Dictionary = {}
var passives: Array[String] = ["orbit", "leech"]
var journey_started: bool = false
var tutorial_flags: Dictionary = {}
var feedback_pending: String = ""
var feedback_color: Color = Color("efc875")
var momentum_left: float = 0.0
var spark_hits: int = 0
var streak: int = 0
var streak_left: float = 0.0
var shake: float = 0.0
var cosmetic_rng := RandomNumberGenerator.new()
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_index: int = 0
var eruption_depth: int = 0
var auto_attack: bool = false
var legacy: Dictionary = {"coins":30,"heart":0,"weapon":0,"spirit":0}
const LEGACY_PATH = "user://legacy.json"

func _ready() -> void:
	get_tree().quit_on_go_back=false
	rng.randomize()
	cosmetic_rng.randomize()
	test_mode = "--smoke-test" in OS.get_cmdline_user_args() or "--autoplay" in OS.get_cmdline_user_args() or "--revision-test" in OS.get_cmdline_user_args()
	capture_mode = "--capture" in OS.get_cmdline_user_args()
	if test_mode: get_tree().create_timer(40).timeout.connect(func(): push_error("TEST_TIMEOUT"); get_tree().quit(1))
	_load_legacy()
	progress = _fresh_run_data()
	_bind_input()
	world = WorldArt.new()
	add_child(world)
	actors = Node3D.new()
	add_child(actors)
	effects = Node3D.new()
	add_child(effects)
	gates = Node3D.new()
	add_child(gates)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 27.5
	camera.position = Vector3(0, 22, 18)
	add_child(camera)
	camera.look_at(Vector3(0, 0, 0))
	camera.current = true
	ui = GameUI.new()
	add_child(ui)
	ui.action.connect(_on_action)
	sound_player = AudioStreamPlayer.new()
	add_child(sound_player)
	for i in range(6):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		sfx_players.append(voice)
	_setup_audio()
	_show_camp()
	if "--revision-test" in OS.get_cmdline_user_args():
		call_deferred("_revision_test")
	elif "--autoplay" in OS.get_cmdline_user_args():
		call_deferred("_autoplay_test")
	elif test_mode:
		call_deferred("_smoke_test")
	elif capture_mode:
		_start_run()
		_on_action("begin")
		player.position = Vector3(0, 0, 2.5)
		_start_capture()

func _bind_input() -> void:
	for action_name in ["left","right","up","down","attack","dash","flame","interact"]:
		if not InputMap.has_action(action_name): InputMap.add_action(action_name)

func _process(delta: float) -> void:
	start_time += delta
	if state in ["playing","chronicle","transition"]: world.tick_worshippers(minf(delta,0.04))
	if state == "playing":
		_tick_game(minf(delta, 0.04))
	else:
		_clear_combat_buffer()
	_update_hud()

func _tick_game(dt: float) -> void:
	cast_pose=maxf(0,cast_pose-dt)
	rooted_left=maxf(0,rooted_left-dt)
	root_ward=maxf(0,root_ward-dt)
	_update_root_mark()
	hit_stop=maxf(0,hit_stop-dt)
	attack_buffer=maxf(0,attack_buffer-dt)
	if hit_stop<=0: attack_pose=maxf(0,attack_pose-dt)
	if not feedback_pending.is_empty():
		_growth_burst(feedback_pending, feedback_color)
		feedback_pending = ""
	momentum_left = maxf(0, momentum_left-dt)
	streak_left -= dt
	if streak_left <= 0: streak = 0
	if journey_started:
		run_seconds += dt
		stage_seconds+=dt
		_tick_waves(dt)
	if journey_started:
		_tick_orbit(dt)
		if state!="playing": return
		_tick_blessings(dt)
		if state!="playing": return
	_tick_buffs(dt)
	attack_cd = maxf(0, attack_cd - dt)
	dash_cd = maxf(0, dash_cd - dt)
	for i in range(3): skill_cds[i]=maxf(0,skill_cds[i]-dt)
	flame_cd=skill_cds[0]
	ultimate_cd=maxf(0,ultimate_cd-dt)
	immunity = maxf(0, immunity - dt)
	_tick_combat_buffer(dt)
	if state!="playing": return
	combo_time -= dt
	if combo_time <= 0: combo = 0
	var move: Vector2 = Input.get_vector("left", "right", "up", "down")
	if ui.move_vector.length() > 0.1: move = ui.move_vector
	var dir := Vector3(move.x, 0, move.y)
	if rooted_left>0: dir=Vector3.ZERO
	if attack_buffer>0 or Input.is_action_pressed("attack") or ui.attack_held or (auto_attack and not _nearest_enemy(float(_weapon()["reach"])+0.5).is_empty()): _attack()
	if Input.is_action_just_pressed("dash"): _request_dash(dir)
	if Input.is_action_just_pressed("flame"): _flame()
	if Input.is_action_just_pressed("interact"): _interact()
	if state != "playing": return
	if dash_left > 0:
		dash_left -= dt
		player.position += dash_dir * 18.0 * dt
		if _boon("dash") > 0:
			for enemy in enemies.duplicate():
				if enemy["hp"] > 0 and not enemy.get("dash_hit", false) and player.position.distance_to(enemy["node"].position) < 1.7:
					enemy["dash_hit"] = true
					_damage_enemy(enemy, 14.0, player.position)
					if state!="playing": return
	elif dir.length() > 0.08:
		tutorial_flags["move"] = true
		var speed: float = 6.6 if progress["equipped"]["robe"] != "iron_robe" else 6.0
		if progress["equipped"]["robe"] == "wind_robe": speed=7.1
		if "swift" in passives: speed*=1.1
		if haste_left>0: speed*=1.25
		player.position += dir * speed * dt
		if attack_pose<=0: facing = dir.normalized()
	player.position = world.constrain_position(player.position)
	player.rotation.y = lerp_angle(player.rotation.y, atan2(-facing.x, -facing.z), minf(1, dt * 18))
	walk_time += dt * (13 if dir.length() > 0.1 else 3)
	player.position.y = absf(sin(walk_time)) * (0.065 if dir.length() > 0.1 else 0.01)
	_animate_player(dt,dir)
	player.visible = immunity <= 0 or fmod(immunity, 0.12) < 0.08
	camera.position = camera.position.lerp(player.position + Vector3(0,22,18), minf(1,dt*8))
	shake = maxf(0,shake-dt*2.2)
	camera.h_offset = cosmetic_rng.randf_range(-shake,shake)
	camera.v_offset = cosmetic_rng.randf_range(-shake,shake)*0.5
	camera.look_at(camera.position - Vector3(0,22,18))
	room_index = world.region_at(player.position)
	var region: Dictionary = world.landmarks[room_index]
	if player.position.distance_to(region["pos"]) < 11 and not region["visited"]:
		region["visited"] = true
		ui.toast("行至 · " + region["name"])
	if boss_spawned and not boss_introduced and player.position.distance_to(world.landmarks[6]["pos"]) < 12:
		boss_introduced = true
		state = "story"
		ui.show_modal(_boss_name(), "百愿娘娘：留在福报里，就不必再失望。\n\n金圈前两秒回复生命，久留定身 1.2 秒，头顶显「定」；转红后即将炸裂。提前离圈，或用踏影解缚脱身，击败她解开愿契。" if chapter==2 else "船夫缚舟锁住了渡口。师父从这里去了上游。\n\n打败缚舟，打开渡口，继续寻找师父。", [{"id":"begin","label":"提灯迎战","detail":"躲开朱红预警，在重击后反击"}], "主线 · 解开愿契" if chapter==2 else "主线 · 解开古渡的锁")
		if chapter==3:
			ui.show_modal("无名判影","判影：来者，报上名字。……怎么又是你？\n\n它会借用你上一次施放的技能；朱圈锁定后离开，留心蓝色判笔弹幕。轮换技能会延长它借招后的破绽。",[{"id":"begin","label":"提灯对簿"}],"主线 · 取回被借走的名字")
		if stage_depth>6:
			ui.show_modal("余烬愿影","卷已收，余烬仍在回响。\n击败本境愿影，可继续挑战或携香火归家。它重现落印、追契锁与双印，看到预警及时换位。",[{"id":"begin","label":"再试锋芒"}],"卷外挑战")
		if stage_depth==6:
			ui.show_modal("百契债身","落印命中会短暂定身，按踏影解缚。追契锁向两侧闪，双印落下前离开朱圈。",[{"id":"begin","label":"先辨名字，再断愿契"}],"城隍夜簿 · 首领现形")
		if stage_depth==5:
			ui.show_modal("陆照川 · 守灯人","师父：你若走了，这盏灯为谁而亮？\n\n三阶段：朱圈落笔后反击；愿环可贴近青圈或退至圈外；笔锋直线锁定后向两侧闪避。",[{"id":"begin","label":"师父，请听我说"}],"终章 · 灯为谁明")
		if chapter==4:
			ui.show_modal("二郎显圣真君","二郎神：看清以后，还敢往前走吗？\n\n天眼初亮时三圈皆未定，显出「实」「虚」后避开实圈。朱圈落点固定；封界青色内圈仅对该招安全。",[{"id":"begin","label":"请真君赐教"}],"主线 · 照破幻相")
		return
	for enemy in enemies.duplicate():
		if enemy["hp"] > 0: _tick_enemy(enemy, dt)
		if state != "playing": return
	_tick_projectiles(dt)
	if state != "playing": return
	if pending_levels > 0:
		pending_levels -= 1
		_show_boons("level")

func _boon(id: String) -> int:
	return int(boon_counts.get(id, 0))

func _weapon() -> Dictionary:
	return Arsenal.WEAPONS[progress["equipped"]["blade"]]

func _base_damage() -> float:
	var value: float=(float(_weapon()["damage"])+int(progress["gear"]["blade"])*4.0+int(legacy["weapon"])*2.0)*(1+0.2*_boon("edge"))
	if progress["equipped"]["robe"]=="crimson_robe" and combo==3: value*=1.25
	if momentum_left>0 and "momentum" in passives: value*=1.35
	if hp<max_hp*0.4: value*=1+0.25*_boon("rage")
	if streak>=10: value*=1+0.15*_boon("fervor")
	if avatar_left>0: value*=1.4*(1+0.2*_boon("overload"))
	return value

func _attack() -> void:
	if state != "playing" or attack_cd > 0 or dash_left > 0 or cast_pose > 0.10: return
	attack_buffer=0
	var data: Dictionary = _weapon()
	attack_pose_duration=clampf(float(data["interval"])*0.6,0.14,0.32)
	attack_pose=attack_pose_duration
	var target: Dictionary = _nearest_enemy(float(data["reach"])+2.0)
	if not target.is_empty(): facing = (target["node"].position-player.position).normalized()
	attack_cd = float(data["interval"])*float(Techniques.ARTS[normal_art]["speed"])*pow(0.88,mini(_boon("quick"),7))
	if haste_left>0 or avatar_left>0: attack_cd/=1.25
	combo = combo%3+1
	combo_time = 1.3
	var reach: float = float(data["reach"])*(1+_boon("reach")*0.20)*(1.35 if normal_art=="thrust" else 1.0)
	var origin: Vector3 = player.position
	var weapon_id: String = {"cleave":"ferry_blade","flurry":"long_sword","thrust":"long_spear","sweep":"iron_staff"}[normal_art]
	var color := Color(data["color"])
	if weapon_id not in ["long_spear","long_sword"]: _arc(origin+Vector3.UP*0.7,facing,reach,color)
	if weapon_id=="long_sword": _bolt(origin+Vector3.UP*0.8,origin+facing*reach+Vector3.UP*0.8,color)
	if weapon_id=="iron_staff": _ring(origin,reach,color,0.24)
	if weapon_id=="long_spear" or (weapon_id=="long_sword" and combo==3):
		_bolt(origin+Vector3.UP*0.8,origin+facing*(reach if weapon_id=="long_spear" else 6.0)+Vector3.UP*0.8,color)
	var weapon: Node3D = player.find_child("Weapon",true,false)
	if weapon:
		if weapon_tween and weapon_tween.is_valid(): weapon_tween.kill()
		weapon.position=Vector3.ZERO
		weapon.rotation=Vector3.ZERO
		var tween:=create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		weapon_tween=tween
		if weapon_id=="long_spear":
			weapon.position.z=-0.9
			tween.tween_property(weapon,"position:z",0.0,0.25)
		elif weapon_id=="iron_staff":
			weapon.rotation.y=-PI
			tween.tween_property(weapon,"rotation:y",0.0,0.32)
		elif progress["equipped"]["blade"]=="heavy_cleaver":
			weapon.rotation.x=-1.2
			tween.tween_property(weapon,"rotation:x",0.35,0.12)
			tween.tween_property(weapon,"rotation:x",0.0,0.25)
		elif weapon_id=="long_sword":
			weapon.position.z=-0.45
			weapon.rotation.y=-0.35
			tween.set_parallel()
			tween.tween_property(weapon,"position:z",0.0,0.15)
			tween.tween_property(weapon,"rotation:y",0.0,0.15)
		else:
			weapon.rotation.y=-1.3
			tween.tween_property(weapon,"rotation:y",0.0,0.22)
	var hit: bool = false
	var impact_count: int = 0
	for enemy in enemies.duplicate():
		var diff: Vector3 = enemy["node"].position-origin
		var in_shape: bool = diff.length() <= reach+enemy["radius"] and (diff.normalized().dot(facing)>float(Techniques.ARTS[normal_art]["arc"]) or diff.length()<0.85)
		if weapon_id=="long_sword" and combo==3 and diff.length()<6.0 and diff.normalized().dot(facing)>0.90: in_shape=true
		if enemy["hp"]>0 and in_shape:
			var amount: float = _base_damage()*(1.6 if combo==3 else 1.0)*(0.85 if normal_art in ["flurry","sweep"] else 1.0)
			if rng.randf()<minf(0.75,0.12*_boon("crit")+(0.12 if "fury" in passives else 0)): amount*=1.8
			if rng.randf()<0.18*_boon("frostbite"): enemy["slow"]=2.0*(1+0.2*_boon("long_control"))
			if rng.randf()<0.20*_boon("venom"): enemy["poison"]=4.0
			if weapon_id=="long_spear" and enemy.get("slow",0.0)>0: amount*=1.35
			if impact_count < (2 if quality=="low" else 4):
				_strike_impact(enemy["node"].position+Vector3.UP, color, combo==3)
				impact_count+=1
			_damage_enemy(enemy,amount,origin)
			if state!="playing": return
			energy=minf(100,energy+6+3*_boon("energy"))
			if enemy["hp"]>0 and weapon_id=="iron_staff" and combo==3:
				enemy["node"].position=world.constrain_position(enemy["node"].position+diff.normalized()*1.1)
			hit=true
	if not journey_started and player.position.distance_to(Vector3(0,0,-3))<reach+1:
		_burst(Vector3(0,1,-3),color,5,0.7)
		hit=true
	if hit:
		ultimate_charge=minf(100,ultimate_charge+3*(1+0.2*_boon("resolve")))
		tutorial_flags["attack"]=true
		hit_stop=(0.028 if data["interval"]<0.3 else 0.045) if combo!=3 else 0.065
		shake=maxf(shake,0.10 if combo!=3 else 0.22)
		_sfx("impactPunch_heavy_000.ogg" if progress["equipped"]["blade"]=="heavy_cleaver" or combo==3 else "impactMetal_light_000.ogg",-9)
		spark_hits+=1
		if ("spark" in passives or progress["equipped"]["lamp"]=="storm_lamp") and spark_hits%3==0:
			_chain_lightning(3,15.0)
			if state!="playing": return
		if combo==3 and _boon("echo")>0:
			_ring(origin,4.2,Color("eedbbb"),0.3)
			for enemy in enemies.duplicate():
				if enemy["node"].position.distance_to(origin)<4.2:
					_damage_enemy(enemy,10.0*_boon("echo"),origin)
					if state!="playing": return

func _dash(direction: Vector3 = Vector3.ZERO) -> void:
	if state != "playing" or dash_cd > 0:
		return
	_cancel_weapon_pose()
	cast_pose=0
	rooted_left=0
	root_ward=0.8
	blessing_exposure=0
	_update_root_mark()
	tutorial_flags["dash"]=true
	momentum_left=2.0
	dash_dir = direction.normalized() if direction.length() > 0.1 else facing
	dash_left = 0.18
	dash_cd = 1.25 * pow(0.82, _boon("dash"))*(0.85 if progress["equipped"]["robe"]=="wind_robe" else 1.0)
	immunity = maxf(immunity, 0.30)
	for enemy in enemies:
		enemy["dash_hit"] = false
	hp=minf(max_hp,hp+3*_boon("lotus_step"))
	if _boon("afterimage")>0:
		for enemy in enemies.duplicate():
			if enemy["node"].position.distance_to(player.position)<3:
				_damage_enemy(enemy,12.0*_boon("afterimage"),player.position)
				if state!="playing": return
	_ring(player.position, 1.0, Color(0.45, 0.83, 0.77, 0.65), 0.3)
	_tone(500, 0.07, 0.07)

func _flame() -> void:
	_request_skill(0)

func _cast_skill(slot: int) -> void:
	if state!="playing" or slot<0 or slot>=3: return
	if slot>=learned_skills.size():
		if journey_started:
			ui.toast("下一次升级时学习新招")
			return
		_show_learning(slot)
		return
	if skill_cds[slot]>0: return
	var id: String=learned_skills[slot]
	active_skill=id
	var data: Dictionary=Techniques.SKILLS[id]
	var rank: int=int(skill_ranks.get(id,1))
	var cost: float=maxf(5,float(data["cost"])-2*_boon("thrift")-(5 if progress["equipped"]["lamp"]=="broken_lamp" else 0)-(3 if progress["equipped"]["robe"]=="sage_robe" else 0))
	if energy<cost:
		ui.toast("灯火不足 · 普攻命中可恢复")
		return
	_cancel_weapon_pose()
	cast_pose=0.24
	varied_cast=id!=last_cast
	last_cast=id
	energy-=cost
	_lamp_cast_effect()
	skill_cds[slot]=float(data["cooldown"])*pow(0.9,_boon("refresh"))*(0.9 if "focus" in passives else 1.0)
	flame_cd=skill_cds[0]
	tutorial_flags["skill"]=true
	var radius: float=(6.5 if id in ["vortex","quake","weak"] else 5.0)*(1+0.1*_boon("flame"))
	var damage: float=(35+int(progress["gear"]["lamp"])*7)*(1+0.35*_boon("flame"))*(1+(rank-1)*0.25)
	if progress["equipped"]["lamp"]=="ember_lamp" and id=="fire": damage*=1.3
	var color:=Color(data["color"])
	_ring(player.position,radius,color,0.5)
	_burst(player.position+Vector3.UP,color,10,2)
	if id=="barrier":
		shield_hp+=30+rank*8
		guard_left=5.0
	elif id=="haste": haste_left=5.0+(rank-1)
	elif id=="heal": hp=minf(max_hp,hp+24+(rank-1)*6)
	elif id=="thunder":
		_chain_lightning(10 if progress["equipped"]["lamp"]=="storm_lamp" else 8,damage*1.2)
	else:
		if id in ["frost","stun"]:
			for i in range(8):
				var pos: Vector3=player.position+Vector3(cos(i*TAU/8),0,sin(i*TAU/8))*2.5
				_bolt(pos,pos+Vector3.UP*(1.7 if id=="frost" else 0.7),color)
		if id=="darts":
			var target: Dictionary=_nearest_enemy(10)
			if not target.is_empty(): facing=(target["node"].position-player.position).normalized()
			for i in range(5): _bolt(player.position+Vector3.UP,player.position+facing.rotated(Vector3.UP,(i-2)*0.2)*9+Vector3.UP,color)
		if id=="vortex":
			for i in range(3): _arc(player.position+Vector3.UP*(0.3+i*0.4),Vector3(cos(i*2.0),0,sin(i*2.0)),radius-i,color)
		for enemy in enemies.duplicate():
			var diff: Vector3=enemy["node"].position-player.position
			if id=="darts":
				if diff.length()>9 or diff.normalized().dot(facing)<0.7: continue
			elif diff.length()>radius+enemy["radius"]: continue
			_apply_skill_status(enemy,id)
			if id=="vortex" and enemy["kind"]!="boss": enemy["node"].position=world.constrain_position(player.position+diff.normalized()*1.7)
			if id=="quake" and enemy["kind"]!="boss": enemy["node"].position=world.constrain_position(enemy["node"].position+diff.normalized()*3.0)
			_damage_enemy(enemy,damage*(0.65 if id in ["weak","poison","frost","vortex"] else 1.0),player.position)
			if state!="playing": return
	hp=minf(max_hp,hp+2*_boon("second_wind"))
	shake=0.20
	_refresh_gear_visual()
	_sfx("impactBell_heavy_000.ogg",-20)

func _apply_skill_status(enemy: Dictionary,id: String) -> void:
	var duration: float=1+0.2*_boon("long_control")
	if id=="frost": enemy["slow"]=3*duration
	if id=="fire" or _boon("burn")>0: enemy["burn"]=3.0
	if id=="poison":
		enemy["poison"]=5.0
		enemy["exposed"]=5*duration
	if id=="weak": enemy["weak"]=5*duration
	if id=="stun": enemy["stun"]=(0.35 if enemy["kind"]=="boss" else 1.4)*duration
	if _boon("expose")>0: enemy["exposed"]=maxf(enemy.get("exposed",0.0),3*duration)

func _nearest_enemy(limit: float) -> Dictionary:
	var target: Dictionary = {}
	for enemy in enemies:
		var distance: float = player.position.distance_to(enemy["node"].position)
		if enemy["hp"] > 0 and distance < limit:
			limit = distance
			target = enemy
	return target

func _spawn_enemy(kind: String, pos: Vector3) -> Dictionary:
	var node: Node3D = world.create_actor(kind,chapter)
	actors.add_child(node)
	node.position = pos
	var health: float = 34
	var speed: float = 4.9
	var radius: float = 0.5
	if kind == "ranger":
		health = 42
		speed = 3.6
	elif kind == "brute":
		health = 130
		speed = 3.3
		radius = 0.8
	elif kind == "boss":
		health = 1500*pow(1.6,stage_depth-1)
		speed = 2.1
		radius = 1.2
	if chapter>=2 and kind!="dummy":
		health*=1.12
	if kind=="dummy":
		health=99999
		speed=0
	var enemy: Dictionary = {"kind":kind,"node":node,"hp":health,"max_hp":health,"speed":speed,"radius":radius,"mode":"chase","timer":rng.randf_range(0.3, 0.9),"target":pos,"tell":null,"count":0,"dash_hit":false,"home":pos,"power":1.0,"burn":0.0,"burn_tick":0.0,"slow":0.0,"poison":0.0,"poison_tick":0.0,"exposed":0.0,"stun":0.0,"weak":0.0}
	enemies.append(enemy)
	_ring(pos, 0.8, Color("8ba7a4"), 0.5)
	return enemy

func _tick_enemy(enemy: Dictionary, dt: float) -> void:
	if enemy["kind"]=="dummy": return
	for status in ["exposed","weak","stun"]: enemy[status]=maxf(0,enemy.get(status,0.0)-dt)
	if enemy.get("poison",0.0)>0:
		enemy["poison"]-=dt
		enemy["poison_tick"]-=dt
		if enemy["poison_tick"]<=0:
			enemy["poison_tick"]=1.0
			_burst(enemy["node"].position+Vector3.UP,Color("a6ca6d"),3,0.5)
			_damage_enemy(enemy,8.0+3*_boon("venom"),player.position)
			if enemy["hp"]<=0: return
	if enemy["stun"]>0: return
	enemy["slow"]=maxf(0,enemy.get("slow",0.0)-dt)
	if enemy.get("burn",0.0)>0:
		enemy["burn"] -= dt
		enemy["burn_tick"] -= dt
		if enemy["burn_tick"]<=0:
			enemy["burn_tick"]=1.0
			_burst(enemy["node"].position+Vector3.UP,Color("e68f55"),3,0.5)
			_damage_enemy(enemy,8.0+8.0*_boon("burn"),player.position)
			if enemy["hp"]<=0: return
	var node: Node3D = enemy["node"]
	if enemy["slow"]>0 and fmod(enemy["slow"],0.5)<dt:
		_ring(node.position,0.7,Color("92d3de"),0.3)
	var diff: Vector3 = player.position - node.position
	diff.y = 0
	var distance: float = diff.length()
	preload("res://scripts/model_library.gd").animate_enemy(node,start_time*9.0+float(node.get_instance_id()%37),enemy["mode"],enemy["timer"])
	if (not journey_started or distance > 28) and not enemy.get("wave",false) and enemy["mode"] != "tell":
		node.position = node.position.move_toward(enemy["home"], dt * 2.5)
		return
	if distance > 0.01:
		node.rotation.y = lerp_angle(node.rotation.y, atan2(-diff.x, -diff.z), minf(1, dt * 7))
	enemy["timer"] -= dt
	if enemy["mode"] == "tell":
		if chapter==4 and enemy["kind"]=="boss": ChapterFour.tick_reveal(self,enemy)
		if is_instance_valid(enemy["tell"]):
			enemy["tell"].scale = Vector3.ONE * (0.94 + sin(start_time * 20) * 0.04)
		if enemy["timer"] <= 0:
			_resolve_enemy_attack(enemy)
		return
	if enemy["mode"] == "recover":
		if enemy["timer"] <= 0:
			enemy["mode"] = "chase"
		return
	var kind: String = enemy["kind"]
	var reach: float = 7.0 if kind == "ranger" else (6.0 if kind == "boss" else 2.1)
	if distance > (5.0 if kind == "ranger" else 1.1):
		var separation: Vector3 = Vector3.ZERO
		for other in enemies:
			if other == enemy:
				continue
			var away: Vector3 = node.position - other["node"].position
			away.y = 0
			if away.length() < 1.2 and away.length() > 0.01:
				separation += away.normalized() * 0.65
		node.position += (diff.normalized() + separation).limit_length(1.1) * float(enemy["speed"]) * (0.42 if enemy["slow"]>0 else 1.0) * dt
		node.position = world.constrain_position(node.position)
	if distance < reach and enemy["timer"] <= 0:
		_telegraph(enemy)

func _telegraph(enemy: Dictionary) -> void:
	enemy["mode"] = "tell"
	enemy["count"] += 1
	var kind: String = enemy["kind"]
	var pos: Vector3 = player.position
	pos.y = 0
	if kind=="boss" and chapter==6:
		ChapterSix.telegraph(self,enemy)
		return
	if kind=="boss" and chapter==5:
		ChapterFive.telegraph(self,enemy)
		return
	if kind=="boss" and chapter==4:
		ChapterFour.telegraph(self,enemy)
		return
	var radius: float = 1.4
	var duration: float = 0.60
	enemy["attack"] = "strike"
	if kind == "boss":
		var pattern: int = int(enemy["count"]) % 3
		if pattern == 0:
			enemy["attack"] = "volley"
			pos = enemy["node"].position
			radius = 2.0
		elif pattern == 1:
			enemy["attack"] = "slam"
			radius = 3.2
		else:
			enemy["attack"] = "blast"
			pos = enemy["node"].position
			radius = 4.8
		duration = 1.1 if enemy["hp"] > enemy["max_hp"] * 0.5 else 0.8
		if chapter==2:
			var prayer: int=int(enemy["count"])%4
			enemy["attack"]={0:"volley",1:"blessing",2:"lance",3:"blast"}[prayer]
			pos=player.position if prayer in [1,2] else enemy["node"].position
			radius={0:2.0,1:3.4,2:2.2,3:4.8}[prayer]
			duration=1.15 if enemy["hp"]>enemy["max_hp"]*0.5 else 0.85
		if chapter==3:
			var pattern3: int=int(enemy["count"])%3
			enemy["attack"]="mirror" if pattern3==0 else ("verdict" if pattern3==1 else "volley")
			enemy["echo_skill"]=last_cast
			enemy["varied"]=varied_cast
			pos=enemy["node"].position if pattern3==2 else player.position
			radius=3.0 if pattern3==0 else (4.2 if pattern3==1 else 2.0)
			duration=1.25 if enemy["hp"]>enemy["max_hp"]*0.5 else 1.0
			if pattern3==0: _float_text(enemy["node"].position+Vector3.UP*3,"借招 · "+Techniques.SKILLS[last_cast]["name"],Color("abd8d5"))
	elif kind == "ranger":
		enemy["attack"] = "shot"
		pos = enemy["node"].position
		radius = 0.8
		enemy["fan_shot"] = chapter == 2 and int(enemy["count"]) % 3 == 0
		if chapter == 2: duration = 0.9
	elif kind == "brute":
		radius = 2.4
		duration = 1.15
	enemy["target"] = pos
	enemy["aim"] = player.position
	enemy["attack_radius"] = radius
	enemy["timer"] = duration
	enemy["tell"] = _disc(pos, radius, Color(0.85, 0.17, 0.11, 0.28))
	if kind == "ranger": preload("res://scripts/ranger_warning.gd").draw(self, enemy)

func _resolve_enemy_attack(enemy: Dictionary) -> void:
	if is_instance_valid(enemy["tell"]):
		enemy["tell"].queue_free()
	enemy["tell"] = null
	var kind: String = enemy["kind"]
	var pos: Vector3 = enemy["target"]
	var radius: float = enemy["attack_radius"]
	if chapter==6 and kind=="boss":
		ChapterSix.resolve(self,enemy)
		return
	if chapter==5 and kind=="boss":
		ChapterFive.resolve(self,enemy)
		return
	if chapter==4 and kind=="boss":
		ChapterFour.resolve(self,enemy)
		return
	if enemy["attack"] in ["mirror","verdict"]:
		var copied: String=enemy.get("echo_skill","fire")
		var color: Color=Color(Techniques.SKILLS[copied]["color"]) if enemy["attack"]=="mirror" else Color("85d3cd")
		_ring(pos,radius,color,0.65)
		_burst(pos+Vector3.UP,color,16,1.6)
		if player.position.distance_to(pos)<radius+0.35:
			var can_control: bool=immunity<=0
			_hurt_player(28.0*float(enemy.get("power",1.0))*(0.75 if enemy.get("weak",0.0)>0 else 1.0))
			if state!="playing": return
			if can_control and enemy["attack"]=="mirror" and copied in ["frost","stun"]:
				rooted_left=0.8
				_update_root_mark()
			if can_control and enemy["attack"]=="mirror" and copied=="vortex": player.position=world.constrain_position(player.position.move_toward(pos,1.8))
		if enemy["attack"]=="mirror" and copied in ["heal","barrier","haste"]:
			enemy["hp"]=minf(enemy["max_hp"],enemy["hp"]+enemy["max_hp"]*0.02)
	elif enemy["attack"]=="blessing":
		_spawn_blessing(pos)
	elif enemy["attack"]=="lance":
		_ring(pos,radius,Color("d97560"),0.3)
		if player.position.distance_to(pos)<radius+0.35: _hurt_player(22.0*(0.75 if enemy.get("weak",0.0)>0 else 1.0))
		if state!="playing": return
	elif enemy["attack"] == "shot":
		_spawn_projectile(enemy["node"].position, (enemy["aim"] - enemy["node"].position).normalized(), 7, 12 * float(enemy.get("power",1.0))*(0.75 if enemy.get("weak",0.0)>0 else 1.0), "ranger_projectile")
		if enemy.get("fan_shot", false):
			var aim: Vector3=(enemy["aim"]-enemy["node"].position).normalized()
			for angle in [-0.22,0.22]: _spawn_projectile(enemy["node"].position,aim.rotated(Vector3.UP,angle),6,9*float(enemy.get("power",1.0))*(0.75 if enemy.get("weak",0.0)>0 else 1.0), "ranger_projectile")
	elif enemy["attack"] == "volley":
		var bolts: int=16 if chapter==2 and enemy["hp"]<enemy["max_hp"]*0.5 else 12
		for i in range(bolts):
			var angle: float = TAU * i / float(bolts) + enemy["count"] * 0.23
			_spawn_projectile(pos, Vector3(cos(angle), 0, sin(angle)), 6, 16*float(enemy.get("power",1.0))*(0.75 if enemy.get("weak",0.0)>0 else 1.0))
	else:
		if enemy["attack"] == "slam":
			enemy["node"].position = pos
		_ring(pos, radius, Color("e2714e"), 0.35)
		var damage: float = (24 if kind == "boss" else (20 if kind == "brute" else 12))*(0.75 if enemy.get("weak",0.0)>0 else 1.0)
		if player.position.distance_to(pos) < radius + 0.35:
			_hurt_player(damage * float(enemy.get("power",1.0)), kind + "_melee")
			if state!="playing": return
	enemy["mode"] = "recover"
	enemy["timer"] = 1.1 if kind == "boss" else 0.85
	if chapter==3 and kind=="boss" and enemy["attack"]=="mirror" and enemy.get("varied",false): enemy["timer"]=2.0

func _spawn_projectile(pos: Vector3, direction: Vector3, speed: float, damage: float, source: String = "boss_projectile") -> void:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	mesh.mesh = sphere
	mesh.material_override = _material(Color("81d6db") if chapter==3 else Color("ed8a57"), true)
	effects.add_child(mesh)
	mesh.position = pos + Vector3.UP * 0.65
	direction.y = 0
	projectiles.append({"node":mesh,"velocity":direction.normalized()*speed,"damage":damage,"life":5.0,"source":source})

func _tick_projectiles(dt: float) -> void:
	for projectile in projectiles.duplicate():
		var node: Node3D = projectile["node"]
		node.position += projectile["velocity"] * dt
		projectile["life"] -= dt
		var hit: bool = Vector2(node.position.x, node.position.z).distance_to(Vector2(player.position.x, player.position.z)) < 0.65
		if hit:
			_hurt_player(projectile["damage"], projectile.get("source", "boss_projectile"))
			if state!="playing": return
		if hit or projectile["life"] <= 0 or Vector2(node.position.x, node.position.z).length() > 57:
			node.queue_free()
			projectiles.erase(projectile)
		if state != "playing":
			return

func _damage_enemy(enemy: Dictionary, damage: float, source: Vector3) -> void:
	if enemy["hp"] <= 0 or not is_instance_valid(enemy["node"]):
		return
	if enemy["kind"]=="dummy":
		_float_text(enemy["node"].position+Vector3.UP*2,str(roundi(damage)),Color("91472f"))
		_burst(enemy["node"].position+Vector3.UP,Color("f0c778"),4,0.6)
		return
	if enemy.get("exposed",0.0)>0: damage*=1.2+0.08*_boon("expose")
	if enemy["hp"]<enemy["max_hp"]*0.3: damage*=1+0.2*_boon("execute")
	if enemy["kind"] in ["boss","brute"]: damage*=1+0.15*_boon("hunter")
	enemy["hp"] -= damage
	var node: Node3D = enemy["node"]
	_hit_reaction(enemy)
	_float_text(node.position + Vector3.UP * 2, str(roundi(damage)), Color("f5d998"))
	var direction: Vector3 = (node.position - source).normalized()
	if enemy["kind"] != "boss":
		node.position = world.constrain_position(node.position + direction * (0.45 if combo==3 else 0.22))
		# A hit only pushes; attack tells keep their timing so enemies remain dangerous.
	_burst(node.position+Vector3.UP,Color("f2c179"),3,0.6)
	if enemy["hp"] <= 0:
		_kill_enemy(enemy)

func _hit_reaction(enemy: Dictionary) -> void:
	var node: Node3D=enemy["node"]
	var old: Tween=enemy.get("hit_tween")
	if old and old.is_valid(): old.kill()
	var flash:=StandardMaterial3D.new()
	flash.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.albedo_color=Color(1.0,0.88,0.60,0.72)
	var meshes: Array=enemy.get("hit_meshes",[])
	if meshes.is_empty():
		meshes=node.find_children("*","MeshInstance3D",true,false)
		enemy["hit_meshes"]=meshes
	for mesh in meshes:
		if is_instance_valid(mesh): mesh.material_overlay=flash
	var tween:=create_tween()
	enemy["hit_tween"]=tween
	tween.tween_property(flash,"albedo_color:a",0.0,0.12)
	tween.tween_callback(func():
		for mesh in meshes:
			if is_instance_valid(mesh): mesh.material_overlay=null)
	var body: Node3D=node.get_node_or_null("Body")
	if body:
		var old_pose: Tween=enemy.get("recoil_tween")
		if old_pose and old_pose.is_valid(): old_pose.kill()
		body.rotation.x=-0.07 if enemy["kind"]=="boss" else -0.26
		var recoil:=create_tween()
		enemy["recoil_tween"]=recoil
		recoil.tween_property(body,"rotation:x",0.0,0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _animate_player(dt: float, direction: Vector3) -> void:
	var body: Node3D=player.get_node_or_null("Body")
	if not body: return
	var moving: float=direction.length()
	pose_time+=dt*(12.0 if moving>0.1 else 2.0)
	var strike: float=sin((0.2+0.8*(1.0-clampf(attack_pose/attack_pose_duration,0,1)))*PI) if attack_pose>0 else 0.0
	var weight: float=1.35 if progress["equipped"]["blade"]=="heavy_cleaver" else 1.0
	var casting: float=sin(clampf(cast_pose/0.24,0,1)*PI)
	var cloak: Node3D=body.get_node_or_null("Cloak")
	if cloak: cloak.rotation.x=sin(pose_time*0.55)*0.025+moving*0.08
	body.rotation.x=lerpf(body.rotation.x,(-0.22 if dash_left>0 else -0.07*moving)-strike*0.12*weight,minf(1,dt*24))
	body.rotation.y=strike*(0.32 if combo%2==0 else -0.32)*weight
	body.rotation.z=sin(pose_time)*0.035*moving
	for side in ["Left","Right"]:
		var leg: Node3D=body.get_node_or_null(side+"Leg")
		if leg:
			leg.rotation.x=sin(pose_time+(PI if side=="Right" else 0))*0.58*moving
		var arm: Node3D=body.get_node_or_null(side+"Arm")
		if arm:
			arm.rotation.x=sin(pose_time+(PI if side=="Left" else 0))*0.22*moving-strike*0.65*weight-casting*(1.1 if side=="Left" else 0.35)

func _kill_enemy(enemy: Dictionary) -> void:
	ChapterFour.clear_marks(enemy)
	ChapterFive.clear_marks(enemy)
	ChapterSix.clear_marks(enemy)
	if is_instance_valid(enemy["tell"]):
		enemy["tell"].queue_free()
	var node: Node3D = enemy["node"]
	var tween := create_tween()
	tween.tween_property(node, "scale", Vector3.ONE * 0.02, 0.25)
	tween.tween_callback(node.queue_free)
	enemies.erase(enemy)
	streak+=1
	streak_left=4.0
	if streak%10==0:
		ui.toast("%d 连斩！灯火 +20" % streak)
		energy=minf(100,energy+20)
		_burst(player.position+Vector3.UP,Color("f3be67"),10,1.5)
	if normal_art=="cleave" and enemy.get("burn",0.0)>0 and eruption_depth<2:
		eruption_depth+=1
		_ring(node.position,2.8,Color("f2a467"),0.3)
		for other in enemies.duplicate():
			if other["node"].position.distance_to(node.position)<2.8:
				_damage_enemy(other,25.0,node.position)
				if state!="playing": return
		eruption_depth-=1
	run_ash += (9 if enemy["kind"] != "boss" else 45)+2*_boon("ash")
	ultimate_charge=minf(100,ultimate_charge+5)
	if "merciful" in passives: shield_hp=minf(30,shield_hp+2)
	kills += 1
	energy = minf(100, energy + 14)
	hp = minf(max_hp, hp + (1 if progress["equipped"]["robe"]=="pilgrim_robe" else 0) + 4 * _boon("drain") + (2 if "leech" in passives else 0))
	xp += ({"grunt":8,"ranger":10,"brute":18}.get(enemy["kind"],8)+_boon("soul")) if enemy["kind"] != "boss" else 0
	while xp >= xp_next:
		xp -= xp_next
		level += 1
		xp_next = _xp_requirement(level)
		pending_levels += 1
		study_points+=1
	if enemy["kind"] == "boss":
		_finish_run(true)

func _hurt_player(amount: float, source: String = "boss") -> void:
	if immunity > 0 or state != "playing" or not journey_started:
		return
	var reduction: float = pow(0.86, _boon("ward")) * (1 - mini(int(progress["gear"]["robe"]), 5) * 0.03)
	if progress["equipped"]["robe"] == "iron_robe":
		reduction *= 0.82
	if "ironwall" in passives: reduction*=0.85
	if guard_left>0: reduction*=0.7
	var damage: float = amount * reduction
	var absorbed: float=minf(shield_hp,damage)
	shield_hp-=absorbed
	damage-=absorbed
	if _boon("thorns")>0:
		for enemy in enemies.duplicate():
			if enemy["node"].position.distance_to(player.position)<3:
				_damage_enemy(enemy,12.0*_boon("thorns"),player.position)
				if state!="playing": return
	if state!="playing": return
	received_hits+=1
	received_damage+=damage
	source = str(stage_depth) + ":" + source
	last_damage_source = source
	var record: Dictionary = damage_sources.get(source, {"hits":0, "health_damage":0.0, "absorbed":0.0, "max_hit":0.0})
	record["hits"] += 1
	record["health_damage"] += minf(hp, damage)
	record["absorbed"] += absorbed
	record["max_hit"] = maxf(record["max_hit"], damage)
	damage_sources[source] = record
	hp = maxf(0, hp - damage)
	immunity = 0.65
	_float_text(player.position + Vector3.UP * 2, "−" + str(roundi(damage)), Color("ed7f6c"))
	_tone(65, 0.15, 0.16)
	if hp <= 0:
		_finish_run(false)

func _reset_journey() -> void:
	found_scroll = {}
	damage_sources.clear()
	last_damage_source = ""
	rooted_left=0
	root_ward=0
	eruption_depth=0
	blessings.clear()
	blessing_exposure=0
	rooted_left=0
	root_ward=0
	rescued=0
	anchored_lights=0
	final_voices.clear()
	ending_choice=""
	restored_names=0
	remembered=0
	released_memories=0
	last_cast="fire"
	varied_cast=false
	received_hits=0
	received_damage=0.0
	attack_buffer=0
	attack_pose=0
	cast_pose=0
	_clear_combat_buffer()
	pose_time=0
	_clear_dynamic()
	journey_started=false
	feedback_pending=""
	momentum_left=0
	spark_hits=0
	streak=0
	streak_left=0
	shake=0
	hit_stop=0
	progress = _fresh_run_data()
	run_ash = 25
	run_gear.clear()
	story_found.clear()
	pickups.clear()
	boon_counts.clear()
	xp = 0
	level = 1
	xp_next = _xp_requirement(1)
	pending_levels = 0
	kills = 0
	combo = 0
	boss_introduced = false
	boss_spawned = false
	run_seconds = 0.0
	stage_seconds=0
	stage_depth=1
	stage_entry_level=1
	earned_incense=0
	wave_clock = 0.4
	wave_number = 0
	orbit_clock = 0.0
	max_hp = 110+int(legacy["heart"])*8
	hp = max_hp
	energy = 40+int(legacy["spirit"])*10
	skill_cds=[0.0,0.0,0.0]
	study_points=0
	shield_hp=0
	shield_clock=0
	guard_left=0
	haste_left=0
	avatar_left=0
	ultimate_charge=0
	ultimate_cd=0
	settled=false
	progress["equipped"]["blade"]=selected_weapon

func _place_player() -> void:
	player=world.create_actor("player")
	actors.add_child(player)
	player.position=Vector3(0,0,3)
	camera.position=player.position+Vector3(0,22,18)
	camera.look_at(player.position)
	facing=Vector3.FORWARD
	dash_left=0
	dash_cd=0
	attack_cd=0
	flame_cd=0
	immunity=0
	room_index=0
	_refresh_gear_visual()
	_apply_quality()
	ui.set_combat_visible(true)

func _start_run() -> void:
	_enter_home(true)

func _enter_home(welcome: bool=false) -> void:
	_reset_journey()
	learned_skills.clear()
	skill_ranks.clear()
	active_skill="fire"
	world.build_map(62183,true)
	_place_player()
	energy=100
	ultimate_charge=100
	_add_pickup("rack",Vector3(-3,0,0),0)
	_add_pickup("manual",Vector3(3,0,1),0)
	_add_pickup("forge",Vector3(3,0,-2),0)
	_add_pickup("bed",Vector3(-4,0,-5),0)
	_add_pickup("portal",Vector3(8,0,4),0)
	state="playing"
	ui.hide_modal()
	if welcome:
		state="story"
		ui.show_modal("竹林里的家", "师父带着宝莲灯灯芯去了上游。先在家准备，再去雾隐渡找他。\n\n左侧兵器架：领取五种兵器。\n右侧藏经台：选普攻、学技能、换绝技与心法。\n院外莲纹传送阵：进入第一张战斗地图。",[{"id":"begin","label":"开始准备"}],"竹隐居 · 安全区域")

func _start_expedition() -> void:
	var starter: Array[String]=learned_skills.duplicate()
	var starting_equipment: Dictionary=progress.duplicate(true)
	selected_weapon=progress["equipped"]["blade"]
	_reset_journey()
	progress=starting_equipment
	_refresh_gear_stats()
	hp=max_hp
	learned_skills=starter
	skill_ranks.clear()
	for id in learned_skills: skill_ranks[id]=1
	journey_started=true
	map_seed=rng.randi_range(1,999999)
	world.chapter=chapter
	world.build_map(map_seed,false)
	world.populate_worshippers()
	_place_player()
	for region in world.landmarks:
		var index: int=region["id"]
		var center: Vector3=region["pos"]
		if index>0 and index<6:
			_add_pickup("chest",center+Vector3(1.5,0,2),index)
			if index in [3,5]: _add_pickup("story",center+Vector3(-3,0,-2),index)
			if index in [2,4]: _add_pickup("heal",center+Vector3(4,0,-3),index)
	if chapter==2:
		for index in [2,4]: _add_pickup("rescue",world.landmarks[index]["pos"]+Vector3(-3,0,3),index)
	Exploration.populate(self)
	state="playing"
	ui.hide_modal()
	ui.toast(_chapter_name()+" · 杀怪升级，7 级或 6 分钟后首领现身")
	_play_chapter_book(false)

func _clear_dynamic() -> void:
	_clear_combat_buffer()
	cast_pose=0
	found_scroll = {}
	for holder in [actors, effects, gates]:
		for child in holder.get_children(): child.free()
	enemies.clear()
	projectiles.clear()
	pickups.clear()

func _clear_projectiles() -> void:
	for projectile in projectiles:
		if is_instance_valid(projectile["node"]):
			projectile["node"].queue_free()
	projectiles.clear()

func _show_boons(reason: String) -> void:
	level_learning=reason=="level"
	state = "boon"
	choices.clear()
	var pool: Array = BOONS.filter(func(b: Dictionary)->bool: return _boon(b["id"])<5).duplicate(true)
	if pool.size()<3: pool=BOONS.duplicate(true)
	while choices.size() < 3:
		var index: int = rng.randi_range(0, pool.size() - 1)
		choices.append(pool.pop_at(index))
	choice_serial += 1
	var buttons: Array = []
	for i in range(choices.size()):
		buttons.append({"id":"boon_%d_%d" % [choice_serial, i], "label":"%d  ·  %s" % [i + 1, choices[i]["name"]], "detail":choices[i]["desc"] + "\n本次闯关生效，可叠加"})
	var title: String = "修为提升 · %d 级" % level if level_learning else "留下一缕残愿"
	var description: String = "经验已满，获得 1 学习点。先选一缕残愿，再学习或升级招式。" if level_learning else "灯火记住了你的选择。不同残愿会改变这一程的战斗方式。"
	ui.show_modal(title, description, buttons, "修为 %d  /  %s" % [level, "探索奖励" if reason == "chest" else "修为提升"])

func _take_boon(index: int) -> void:
	if state != "boon" or index < 0 or index >= choices.size():
		return
	var boon: Dictionary = choices[index]
	boon_counts[boon["id"]] = _boon(boon["id"]) + 1
	if boon["id"] == "health":
		max_hp += 22
		hp = minf(max_hp, hp + 35)
	state = "playing"
	ui.hide_modal()
	_queue_feedback("升级 · "+boon["name"],Color("edc76d"))
	if level_learning and study_points>0: _show_skills()


func _finish_run(victory: bool) -> void:
	if settled or not journey_started or state in ["transition","dying","chronicle","last_words","ending_choice","ending_voice"]: return
	if victory:
		earned_incense+=35
		if chapter==1:
			legacy["chapter"]=2
			_save_legacy()
		state="transition"
		ui.set_combat_visible(false)
		if chapter==2: world.wake_worshippers(-1)
		if chapter==2 and not test_mode and not capture_mode:
			state="chronicle"
			ui.hide_modal()
			ui.toast("愿契已断 · 求愿者缓缓起身")
			get_tree().create_timer(2.5).timeout.connect(func():
				if state=="chronicle" and journey_started: _begin_last_words()
			)
		else: _begin_last_words()
		return
	state="dying"
	death_serial+=1
	var serial: int=death_serial
	ui.set_combat_visible(false)
	ui.hide_modal()
	player.visible=true
	var body: Node3D=player.get_node("Body")
	var fall:=create_tween()
	fall.tween_property(body,"rotation:z",1.4,0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.parallel().tween_property(body,"position:y",-0.35,0.55)
	fall.tween_interval(0.35)
	fall.tween_property(player,"scale",Vector3.ONE*0.04,0.65)
	_burst(player.position+Vector3.UP,Color("9bb8b2"),12,1.8)
	get_tree().create_timer(1.7).timeout.connect(func():
		if state=="dying" and death_serial==serial: _complete_death())

func _complete_death() -> void:
	if state!="dying": return
	var earned: int=earned_incense+mini(kills/4,150)
	var retained: int=earned/2
	var summary: Dictionary={"victory":false,"chapter":chapter,"depth":stage_depth,"kills":kills,"level":level,"seconds":run_seconds,"reward":retained,"lost_incense":earned-retained,"damage":received_damage,"hits":received_hits}
	legacy["coins"]+=retained
	_save_legacy()
	_enter_home(false)
	last_result=summary
	settled=true
	state="result"
	ui.show_modal("灯灭归家","倒在第 %d 境 · 修为 %d · 击败 %d 名敌人\n本次香火带回 %d，遗失 %d。\n\n本次装备强化、技能、残愿和烬砂清零。家中香火与永久根基保留。"%[summary["depth"],summary["level"],summary["kills"],retained,summary["lost_incense"]],[{"id":"back_home","label":"回到院中，重新准备"}],"死亡结算")

func _advance_stage() -> void:
	if state!="transition": return
	var kept: Dictionary={}
	for key in ["hp","max_hp","energy","attack_cd","dash_cd","dash_left","flame_cd","immunity","ultimate_charge","ultimate_cd","shield_hp","guard_left","haste_left","avatar_left","skill_cds"]: kept[key]=get(key)
	_clear_dynamic()
	blessings.clear()
	blessing_exposure=0
	rooted_left=0
	root_ward=0
	stage_depth+=1
	chapter=mini(stage_depth,6)
	stage_seconds=0
	stage_entry_level=level
	boss_spawned=false
	boss_introduced=false
	story_found.clear()
	rescued=0
	anchored_lights=0
	final_voices.clear()
	restored_names=0
	remembered=0
	released_memories=0
	last_cast="fire"
	varied_cast=false
	wave_clock=0.8
	map_seed=rng.randi_range(1,999999)
	world.chapter=chapter
	world.build_map(map_seed,false)
	world.populate_worshippers()
	_place_player()
	for key in kept: set(key,kept[key])
	for region in world.landmarks:
		var index: int=region["id"]
		if index>0 and index<6:
			_add_pickup("chest",region["pos"]+Vector3(1.5,0,2),index)
			if index in [2,4]: _add_pickup("heal",region["pos"]+Vector3(4,0,-3),index)
			if stage_depth in [2,3,4,5,6] and index in [3,5]: _add_pickup("story",region["pos"]+Vector3(-3,0,-2),index)
			if stage_depth==2 and index in [2,4]: _add_pickup("rescue",region["pos"]+Vector3(-3,0,3),index)
			if stage_depth==3 and index in [2,4]: _add_pickup("memory",region["pos"]+Vector3(-3,0,3),index)
			if stage_depth==6 and index in [2,4]: _add_pickup("restore_name",region["pos"]+Vector3(-3,0,3),index)
			if stage_depth==5 and index in [1,2,4]: _add_pickup("voice",region["pos"]+Vector3(-3,0,3),index)
			if stage_depth==4 and index in [2,4]: _add_pickup("anchor",region["pos"]+Vector3(-3,0,3),index)
			if stage_depth==3 and index==1: _add_pickup("mengpo",region["pos"]+Vector3(0,0,-1),index)
	Exploration.populate(self)
	state="playing"
	ui.hide_modal()
	ui.set_combat_visible(true)
	ui.toast(_chapter_name()+" · 状态保留，敌人更强")
	_play_chapter_book(false)

func _item_slot(id: String) -> String:
	if id in Arsenal.WEAPONS:
		return "blade"
	if id in Arsenal.ROBES:
		return "robe"
	return "lamp"

func _show_camp() -> void:
	state = "camp"
	_clear_dynamic()
	world.build_map(62183,true)
	_apply_quality()
	player = world.create_actor("player")
	actors.add_child(player)
	player.position = Vector3(4,0,3)
	camera.position = Vector3(0,22,18)
	camera.look_at(Vector3.ZERO)
	ui.set_combat_visible(false)
	ui.show_modal("烬 灯 行", "一盏残灯，一卷山水，一条被藏起的归途。\n\n自由穿行于每次重绘的墨境，杀怪升级、组合残愿，迎战各章首领。\n每次出门重选搭配，香火钱用于修习永久根基。", [{"id":"start","label":"提灯入画","detail":"先回竹隐居整备，再经传送阵出发"},{"id":"guide","label":"行路须知","detail":"操作与成长规则"},{"id":"audio","label":"声音设置","detail":"音乐与音效音量"},{"id":"about","label":"关于此卷","detail":"版本与第三方许可"}], "水墨动作肉鸽 · 可玩原型 0.7.1")

func _show_equipment() -> void:
	if journey_started:
		state="equipment"
		ui.show_modal("本次行装","兵器：%s\n衣甲：%s\n灵珠：%s\n修为 %d · 待结算香火 %d\n\n此行搭配锁定，战斗中不能换装或锻造。"%[GEAR_NAMES[progress["equipped"]["blade"]],GEAR_NAMES[progress["equipped"]["robe"]],GEAR_NAMES[progress["equipped"]["lamp"]],level,earned_incense+mini(kills/4,150)],[{"id":"resume","label":"继续前行"}],"行囊")
		return
	state = "equipment"
	var buttons: Array = []
	for slot in ["blade","robe","lamp"]:
		var lvl: int = progress["gear"][slot]
		buttons.append({"id":"slot_"+slot,"label":SLOT_NAMES[slot]+" · "+GEAR_NAMES[progress["equipped"][slot]]+" +"+str(lvl),"detail":"查看属性、装配、锻造 · 已拥有 %d 件" % progress["owned"][slot].size()})
	buttons.append({"id":"techniques","label":"武学搭配","detail":"普攻套路、三招技能、绝技、心法"})
	if not journey_started: buttons.append({"id":"legacy","label":"修习根基","detail":"香火钱 %d · 永久提升初始能力" % legacy["coins"]})
	buttons.append({"id":"resume","label":"继续探索"})
	ui.show_modal("行囊", "本局烬砂 %d\n锻造等级跟随装备槽位，切换装备时保留。靠近炉台可锻造。\n这一程结束时，装备和强化一并重置。" % run_ash, buttons, "本局装备")

func _show_slot(slot: String) -> void:
	state = "slot_"+slot
	var lvl: int = progress["gear"][slot]
	var cost: int = 25+20*lvl
	var buttons: Array = []
	for id in progress["owned"][slot]:
		var equipped: bool = progress["equipped"][slot] == id
		buttons.append({"id":"equip_"+id,"label":GEAR_NAMES[id]+(" · 已装备" if equipped else " · 装备"),"detail":_gear_description(id),"disabled":equipped})
	var near_forge: bool = player.position.distance_to(Vector3(3,0,-2))<4.5
	buttons.append({"id":"upgrade_"+slot,"label":"已达 +3" if lvl>=3 else "锻造至 +%d · %d 烬砂" % [lvl+1,cost],"detail":({"blade":"每级兵器伤害 +4","robe":"每级生命 +10、减伤 +3%","lamp":"每级技能基础伤害 +7"}[slot] if near_forge else "靠近炉台锻造"),"disabled":lvl>=3 or run_ash<cost or not near_forge})
	buttons.append({"id":"equipment","label":"继续"})
	buttons.append({"id":"resume","label":"拿好兵器，继续"})
	ui.show_modal(SLOT_NAMES[slot]+" · +"+str(lvl),"本局烬砂 %d\n锻造与装配会立即影响当前战斗。" % run_ash,buttons,"兵器架 · 五种兵器免费领取" if slot=="blade" else "本局整备")

func _gear_description(id: String) -> String:
	if id in Arsenal.WEAPONS: return Arsenal.WEAPONS[id]["desc"]
	return Arsenal.ROBES[id]["desc"] if id in Arsenal.ROBES else Arsenal.LAMPS.get(id,{}).get("desc","")

func _show_journal() -> void:
	state = "journal"
	var body: String = "序 · 师父陆照川带着宝莲灯灯芯，消失在雾隐渡。\n目标：击败镇渡使，解开古渡的锁。"
	body += "\n\n线索一：师父乘船去了上游的听愿祠。" if 3 in story_found else "\n\n探索渡口，寻找师父留下的线索。"
	body += "\n\n线索二：缚舟在等失散的女儿，不肯让任何船离开。" if 5 in story_found else ""
	if chapter==2:
		body="第二章 · 解开听愿祠愿契，击败百愿娘娘。\n已唤醒求愿者 %d / 2。金圈短暂回血，久留定身 1.2 秒，可用踏影解缚，转红后炸裂；走出或踏影脱身。"%rescued
		if 3 in story_found: body+="\n\n愿簿删去的不止痛苦，还有拒绝和离开的能力。"
		if 5 in story_found: body+="\n\n师父明知真相仍在修灯，他所保护的孩子是谁？"
	if chapter==3:
		body="第三章 · 击败无名判影，取回残籍。\n留名 %d / 放下 %d。亡魂与孟婆可交互；探索残籍巷、照魂碑可读线索。\n首领借用上一招，看到朱圈先换位，轮换技能可延长破绽。"%[remembered,released_memories]
	if chapter==4:
		body="第四章 · 与二郎神交手，取得师父旧誓。\n已稳归灯 %d / 2；照影亭和回灯崖可交互，问心石与旧誓碑可读残页。\n天眼显形后避实圈；封界时贴近青色内圈，或退至外圈之外。"%anchored_lights
	if stage_depth==5:
		body="第五章 · 战胜陆照川，决定灯的去留。\n已听心愿 %d / 3：灯市、长明亭、守门庭。照心池、断契碑可读残页。\n听完三种心愿解锁留门，战后可补听。避开朱圈、愿环和直线笔锋，攻击间隙反击。"%final_voices.size()
	elif stage_depth==6:
		body="卷外六 · 击败百契债身，核清错账。\n已辨错契 %d / 2；照账亭、还契庭可交互，无主巷、公议碑有残页。\n离开朱印、向链线两侧走；定身可用踏影解缚。"%restored_names
	elif stage_depth>6:
		body="卷外 · 余烬回响。\n继续挑战更强敌群；本次修为与装备仍保留。击败愿影后可继续或结算归家。"
	ui.show_modal("灯中记忆",body,[{"id":"resume","label":"继续探索"}],"本局主线")

func _on_action(id: String) -> void:
	if Exploration.handle(self, id): return
	if state=="ending_voice":
		if id=="ending_return": _show_final_choice()
		return
	if state=="ending_choice":
		if id=="ending_listen":
			for key in [1,2,4]:
				if key not in final_voices:
					_hear_final_voice(key,true)
					return
		elif id.begins_with("ending_"):
			var choice: String=id.trim_prefix("ending_")
			if choice not in ChapterFive.ENDINGS: return
			if choice=="open" and final_voices.size()<3: return
			ending_choice=choice
			_play_chapter_book(true)
		return
	if state=="last_words":
		if id=="words_next": _next_last_words()
		elif id=="words_skip":
			if words_tween: words_tween.kill()
			ui._modal_description.visible_characters=-1
			_play_chapter_book(true)
		return
	if state=="memory_choice":
		if id not in ["memory_keep","memory_release"]: return
		world.release_river_soul(memory_id)
		memory_id=-1
		study_points+=1
		if id=="memory_keep":
			remembered+=1
			shield_hp=minf(60,shield_hp+20)
		else:
			released_memories+=1
			hp=minf(max_hp,hp+25)
			energy=minf(100,energy+20)
		state="story"
		ui.show_modal("亡魂过河","他把名字写回家书：原来记得她，也可以往前走。" if id=="memory_keep" else "他饮下汤，把信放进河灯：谢谢你，没有替我决定该痛多久。",[{"id":"begin","label":"送他一程"}],"学习点 +1")
		return
	if state=="chronicle": return
	if state=="transition":
		if id=="continue_stage": _advance_stage()
		elif id=="cash_out": _cash_out()
		return
	if journey_started:
		if id=="retreat":
			ui.toast("此行只能向前 · 死亡后归家")
			return
		if id in ["weapons","techniques","equipment"] or id.begins_with("equip_") or id.begins_with("upgrade_") or id.begins_with("forge_") or id.begins_with("choose_") or id.begins_with("slot_"):
			ui.toast("出发后搭配锁定 · 升级时可精进招式")
			return
	if id=="back_home" and state=="result":
		state="playing"
		ui.hide_modal()
		return
	if id=="weapons" and state in ["playing","equipment"]:
		_show_slot("blade")
		return
	if id=="techniques" and state in ["playing","equipment","skills","learning","arts","ultimates","minds","boonbook","chapters"]:
		_show_techniques()
		return
	if id in ["arts","ultimates","minds"] and state=="techniques":
		_show_catalog(id)
		return
	if id=="boonbook" and state=="techniques":
		state="boonbook"
		var cards: Array=[]
		for boon in BOONS: cards.append({"id":"none","label":boon["name"]+" · %d / 5"%_boon(boon["id"]),"detail":boon["desc"],"disabled":true})
		cards.append({"id":"techniques","label":"返回武学"})
		ui.show_modal("残愿图鉴","升级时随机三选一。本局生效，每种最多叠加 5 层。",cards,"32 种残愿")
		return
	if id.begins_with("study_") and state=="skills":
		_show_learning(int(id.trim_prefix("study_")))
		return
	if id.begins_with("learn_"):
		_learn_skill(id.trim_prefix("learn_"))
		return
	if id=="rank_skill" and state=="learning" and journey_started and study_points>0 and learning_slot<learned_skills.size():
		var skill: String=learned_skills[learning_slot]
		if int(skill_ranks[skill])<5:
			skill_ranks[skill]+=1
			study_points-=1
			_queue_feedback("技能精进 · "+Techniques.SKILLS[skill]["name"],Color(Techniques.SKILLS[skill]["color"]))
		_show_skills()
		return
	if id.begins_with("choose_"):
		var pieces: PackedStringArray=id.split("_",true,2)
		if pieces.size()!=3 or state!=pieces[1]: return
		var chosen: String=pieces[2]
		if state=="arts" and chosen in Techniques.ARTS: normal_art=chosen
		elif state=="ultimates" and chosen in Techniques.ULTIMATES:
			ultimate_id=chosen
			ultimate_cd=maxf(ultimate_cd,1.0)
		elif state=="minds" and chosen in Techniques.MINDS:
			if chosen in passives: passives.erase(chosen)
			elif passives.size()<2: passives.append(chosen)
			else:
				ui.toast("先点一部已装心法卸下，再选新的")
				return
		_queue_feedback("武学搭配已调整",Color("b8d1ac"))
		_refresh_gear_visual()
		_show_catalog(state)
		return
	if id.begins_with("skill_") and state=="playing":
		_request_skill(int(id.trim_prefix("skill_")))
		return
	if id=="ultimate":
		_ultimate()
		return
	if id=="auto" and state=="playing":
		auto_attack=not auto_attack
		ui.toast("自动普攻已开启 · 自己移动与释放绝学" if auto_attack else "自动普攻已关闭 · 按住攻击出招")
		return
	if id=="legacy" and state=="equipment" and not journey_started:
		_show_legacy()
		return
	if id.begins_with("legacy_") and state=="legacy" and not journey_started:
		var key: String=id.trim_prefix("legacy_")
		if key not in ["heart","weapon","spirit"]: return
		var rank: int=int(legacy[key])
		var cost: int=20+rank*15
		if rank<5 and int(legacy["coins"])>=cost:
			legacy["coins"]-=cost
			legacy[key]=rank+1
			_save_legacy()
			_refresh_gear_stats()
			if key=="heart": hp=minf(max_hp,hp+8)
			if key=="spirit": energy=minf(100,energy+10)
			_queue_feedback("心法精进",Color("e9c880"))
		_show_legacy()
		return
	if id.begins_with("quality_") and state=="quality":
		quality=id.trim_prefix("quality_")
		_apply_quality()
		state="playing"
		ui.hide_modal()
		ui.toast("画质已切换")
		return
	if id.begins_with("boon_"):
		var parts: PackedStringArray = id.split("_")
		if parts.size()==3 and int(parts[1])==choice_serial: _take_boon(int(parts[2]))
		return
	if id.begins_with("slot_") and state == "equipment":
		_show_slot(id.trim_prefix("slot_"))
		return
	if id.begins_with("upgrade_") and state.begins_with("slot_"):
		var slot: String = id.trim_prefix("upgrade_")
		var lvl: int = progress["gear"].get(slot,3)
		var cost: int = 25+20*lvl
		if lvl<3 and run_ash>=cost and player.position.distance_to(Vector3(3,0,-2))<4.5:
			run_ash -= cost
			progress["gear"][slot]+=1
			_refresh_gear_stats()
			_queue_feedback("锻造 +"+str(lvl+1),Color("efc772"))
		_show_slot(slot)
		return
	if id.begins_with("equip_") and state.begins_with("slot_"):
		var item: String = id.trim_prefix("equip_")
		var slot: String = _item_slot(item)
		if item in progress["owned"][slot]:
			progress["equipped"][slot]=item
			if slot=="blade": selected_weapon=item
			_refresh_gear_stats()
			_refresh_gear_visual()
			tutorial_flags["loadout"]=true
			_queue_feedback("换装 · "+GEAR_NAMES[item],Color("efc772"))
		_show_slot(slot)
		return
	if id.begins_with("chapter_") and state=="chapters":
		var selected: int=int(id.trim_prefix("chapter_"))
		if selected>=1 and selected<=mini(2,int(legacy.get("chapter",1))):
			chapter=selected
			_start_expedition()
		return
	if id=="audio" and state in ["paused","camp"]:
		audio_return=state
		state="audio"
		ui.show_audio(music_volume,sfx_volume)
		return
	if id=="audio_back" or (id=="pause" and state=="audio"):
		_save_audio()
		if audio_return=="camp": _show_camp()
		else:
			state="playing"
			_on_action("pause")
		return
	match id:
		"start":
			if state == "camp": _start_run()
		"restart":
			if state == "result": _start_run()
		"begin":
			if state == "story":
				state = "playing"
				ui.hide_modal()
		"resume":
			if state in ["paused","equipment","skills","journal","map","loot","quality","legacy","techniques","learning","arts","ultimates","minds","boonbook","chapters"] or state.begins_with("slot_"):
				state = "playing"
				ui.hide_modal()
		"camp":
			if state in ["result","guide","about"]: _show_camp()
		"equipment":
			if state.begins_with("slot_") or state in ["skills","legacy"]: _show_equipment()
		"inventory":
			if state == "playing": _show_equipment()
			elif state == "equipment": _on_action("resume")
		"skills":
			if state in ["equipment","techniques","learning"]: _show_skills()
		"journal":
			if state in ["playing","paused","map"]: _show_journal()
		"guide":
			if state == "camp":
				state = "guide"
				ui.show_modal("行路须知", "左摇杆移动 · 右下普攻 · 弧形三个技能键\n独立踏影闪避 · 满战意释放绝技 · 右上打开武学\n\n命中敌人积攒灯火与战意，技能消耗灯火，绝技消耗满格战意。\n击败敌人提升修为、三选一强化技能；探索宝箱获得残愿。\n出发前在家中炉台锻造；途中仅在升级时精进招式。局内装备与强化属于当前行程；香火钱与家传心法永久保留。\n达到修为 7 级或存活 6 分钟，缚舟现身；击败首领后选择继续或全额归家；死亡损失一半本次香火。", [{"id":"camp","label":"返回卷首"}], "操作与规则")
		"about":
			if state == "camp":
				state="about"
				ui.show_modal("关于此卷", "烬灯行 · 0.7.1 开发试玩\n原创程序化场景与玩法原型。\n引擎：Godot Engine，MIT 许可。\n字体：Noto Sans SC，SIL Open Font License 1.1。\n音效与粒子：Kenney，CC0 1.0。\n完整许可原文随安装包资源附带。\n\n本版本的战斗平衡、美术细节与手机性能仍在打磨。", [{"id":"camp","label":"返回卷首"}], "JIN DENG XING")
		"attack":
			if state=="playing":
				attack_buffer=0.16
				_attack()
		"dash":
			var move: Vector2 = ui.move_vector
			if move.length()<0.1: move=Input.get_vector("left","right","up","down")
			_request_dash(Vector3(move.x,0,move.y))
		"flame": _flame()
		"interact": _interact()
		"map":
			if state == "playing":
				state="map"
				ui.show_modal("山水有迹，行路由你", "墨境编号 %06d\n\n走近地标后，小地图才会记下它。首领出现后才会显示首领标记。\n整片陆地可自由穿行，沿任意方向探索。\n\n沿任意方向寻找宝箱与师父的短笺。\n途中寻找残愿与清露，装备只能出发前准备。" % map_seed,[{"id":"resume","label":"继续探索"},{"id":"journal","label":"查看主线灯签"}],"雾隐渡 · 全境")
			elif state == "map": _on_action("resume")
		"pause":
			if state in ["equipment","skills","journal","map","quality","legacy","techniques","learning","arts","ultimates","minds","boonbook","chapters"] or state.begins_with("slot_"):
				_on_action("resume")
			elif state == "paused": _on_action("resume")
			elif state == "playing":
				state="paused"
				ui.show_modal("暂歇", "修为 %d · 本局击败 %d 名敌人\n主线灯签 %d / 2 · 本局烬砂 %d\n\n击败首领后可选择继续或全额归家；死亡只保留本次一半香火。" % [level,kills,story_found.size(),run_ash],[{"id":"resume","label":"继续探索"},{"id":"journal","label":"灯中记忆"},{"id":"quality","label":"画质与性能"},{"id":"audio","label":"声音设置","detail":"背景音乐与游戏音效独立调节"}],"PAUSED")
		"quality":
			if state=="paused":
				state="quality"
				ui.show_modal("画质与性能", "按手机表现选择合适的档位。\n实际帧率会随设备性能和战斗规模变化。", [{"id":"quality_low","label":"省电","detail":"较低画面分辨率 · 关闭阴影 · 30 帧上限"},{"id":"quality_balanced","label":"均衡","detail":"中等画面分辨率 · 2 倍抗锯齿 · 60 帧上限"},{"id":"quality_high","label":"精细","detail":"原生画面分辨率 · 4 倍抗锯齿 · 60 帧上限"},{"id":"resume","label":"保持当前设置"}], "画面设置")
		"mute":
			if state == "paused":
				muted=not muted
				state="playing"
				_on_action("pause")
		"retreat":
			if state == "paused": _finish_run(false)
		"chest_boon":
			if state == "loot": _show_boons("chest")

func _room_title() -> String:
	return world.landmarks[room_index]["name"] if not world.landmarks.is_empty() else "雾隐渡"

func _update_hud() -> void:
	if is_instance_valid(player): Exploration.update_labels(self)
	if not is_instance_valid(ui) or not is_instance_valid(player): return
	var boss_hp: float = 0
	var boss_max: float = 0
	var nearby: int = 0
	for enemy in enemies:
		if enemy["kind"]!="dummy" and player.position.distance_to(enemy["node"].position)<14: nearby+=1
		if enemy["kind"] == "boss" and player.position.distance_to(enemy["node"].position)<17:
			boss_hp=enemy["hp"]
			boss_max=enemy["max_hp"]
	if is_instance_valid(world.boss_place_title): world.boss_place_title.visible=boss_max<=0
	var pickup: Dictionary = _nearby_pickup()
	var prompt: String = "击败首领通关 · 沿途寻找遗卷与宝箱"
	if not pickup.is_empty(): prompt="交互 · "+_pickup_name(pickup["kind"])
	var boss_dist: int = roundi(player.position.distance_to(world.landmarks[6]["pos"])) if journey_started else 0
	var hud_costs: Array=[0.0,0.0,0.0]
	for i in range(learned_skills.size()): hud_costs[i]=maxf(5,float(Techniques.SKILLS[learned_skills[i]]["cost"])-2*_boon("thrift")-(5 if progress["equipped"]["lamp"]=="broken_lamp" else 0)-(3 if progress["equipped"]["robe"]=="sage_robe" else 0))
	ui.update_hud({"interact_label":{"scroll":"参悟遗卷","chest":"开启宝箱","supply":"取用补给","story":"阅读灯签","heal":"取用清露","portal":"传送出发","rack":"更换兵器","manual":"学习武学","forge":"升级装备","bed":"饮茶休整"}.get(pickup.get("kind", ""), "交互"),"skill_costs":hud_costs,"hp":hp,"max_hp":max_hp,"energy":energy,"max_energy":100,"xp":xp,"xp_next":xp_next,"stage_depth":stage_depth,"boss_level":stage_entry_level+6,"room":_chapter_name(),"title":_room_title(),"auto":auto_attack,"objective":_tutorial_prompt() if not journey_started else prompt,"skill_name":Techniques.SKILLS[active_skill]["name"],"learned":learned_skills,"skill_cds":skill_cds,"skill_ranks":skill_ranks,"study":study_points,"ultimate_name":Techniques.ULTIMATES[ultimate_id]["name"],"ultimate_id":ultimate_id,"ultimate_charge":ultimate_charge,"ultimate_cd":ultimate_cd,"art_name":Techniques.ARTS[normal_art]["name"],"shield":shield_hp,"weapon_name":GEAR_NAMES[progress["equipped"]["blade"]],"interact_available":not pickup.is_empty(),"portal_near":not pickup.is_empty() and pickup["kind"]=="portal","streak":streak,"home":not journey_started,"enemies":nearby,"ash":run_ash,"boss_hp":boss_hp,"boss_max":boss_max,"boss_name":_boss_name(),"dash_cd":dash_cd,"flame_cd":flame_cd,"map_points":_visible_map_points(),"player_pos":Vector2(player.position.x,player.position.z),"boss_dist":boss_dist,"story_count":story_found.size(),"seed":map_seed,"level":level,"seconds":stage_seconds,"wave":wave_number,"boss_spawned":boss_spawned})

func _apply_quality() -> void:
	var viewport: Viewport=get_viewport()
	viewport.scaling_3d_scale={"low":0.65,"balanced":0.85,"high":1.0}.get(quality,0.85)
	viewport.msaa_3d={"low":0,"balanced":1,"high":2}.get(quality,1)
	Engine.max_fps=30 if quality=="low" else 60
	for sun in world.find_children("*","DirectionalLight3D",true,false):
		sun.shadow_enabled=quality!="low"

func _notification(what: int) -> void:
	if is_instance_valid(music_player):
		if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
			music_player.stream_paused=true
			_save_audio()
		elif what==NOTIFICATION_APPLICATION_FOCUS_IN: music_player.stream_paused=false
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and state=="playing" and is_instance_valid(ui):
		_on_action("pause")
	elif what==NOTIFICATION_WM_GO_BACK_REQUEST and is_instance_valid(ui):
		if state=="camp": get_tree().quit()
		else: _on_action("pause")

func _fresh_run_data() -> Dictionary:
	return {"gear":{"blade":0,"robe":0,"lamp":0},"owned":{"blade":["ferry_blade","long_sword","long_spear","iron_staff","heavy_cleaver"],"robe":Arsenal.ROBES.keys(),"lamp":Arsenal.LAMPS.keys()},"equipped":{"blade":"ferry_blade","robe":"pilgrim_robe","lamp":"broken_lamp"}}

func _refresh_gear_stats() -> void:
	max_hp = 110 + int(legacy["heart"])*8 + int(progress["gear"]["robe"])*10 + _boon("health")*22
	if progress["equipped"]["robe"]=="iron_robe": max_hp+=16
	hp = minf(hp,max_hp)

func _add_pickup(kind: String, pos: Vector3, id: int) -> void:
	var node := Node3D.new()
	gates.add_child(node)
	node.position=pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.8,0.6,0.55) if kind=="chest" else Vector3(0.4,0.9,0.4)
	if kind=="forge": box.size=Vector3(1.3,0.9,1.1)
	mesh.mesh=box
	if kind in ["rack","manual","portal","bed","memory","mengpo","scroll"]: mesh.visible=false
	mesh.material_override=_material(Color("78392f") if kind in ["chest","forge"] else Color("48564b"))
	node.add_child(mesh)
	mesh.position.y=0.35
	Exploration.decorate(self, node, kind)
	_ring(Vector3.ZERO,0.75,Color("7d5440"),0,node)
	var label := Label3D.new()
	label.text=_pickup_name(kind)
	label.name="InteractionTitle"
	label.font_size=40
	label.pixel_size=0.019
	label.modulate=Color("fff3d5")
	label.outline_size=9
	label.outline_modulate=Color("202924")
	label.shaded=false
	label.no_depth_test=true
	label.visibility_range_end=33
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	if ResourceLoader.exists("res://assets/NotoSansSC.ttf"): label.font=load("res://assets/NotoSansSC.ttf")
	node.add_child(label)
	label.position.y=1.4
	preload("res://scripts/world_label.gd").finish(label)
	pickups.append({"kind":kind,"pos":pos,"id":id,"used":false,"node":node})

func _pickup_name(kind: String) -> String:
	if kind == "scroll": return "拾取武学遗卷"
	if kind == "supply": return "打开补给箱"
	return {"chest":"打开遗珍宝箱","story":"阅读灯签","heal":"取用清露","forge":"炉台 · 锻造","rack":"兵器架 · 换装","bed":"茶桌 · 休整","manual":"藏经台 · 学武","restore_name":"归名 · 核对愿契","voice":"灯中人 · 听心愿","anchor":"归灯 · 稳住裂隙","memory":"亡魂 · 问愿","mengpo":"孟婆 · 问路","rescue":"求愿者 · 唤醒","portal":"传送阵 · 选择墨境"}.get(kind,"交互")

func _nearby_pickup() -> Dictionary:
	var best: Dictionary={}
	var distance: float=3.0
	for pickup in pickups:
		if pickup["used"]: continue
		var d: float=player.position.distance_to(pickup["pos"])
		if d<distance:
			best=pickup
			distance=d
	return best

func _interact() -> void:
	if state!="playing": return
	var pickup: Dictionary=_nearby_pickup()
	if pickup.is_empty():
		ui.toast("靠近遗珍、灯签、清露或炉台后交互")
		return
	if pickup["kind"] == "scroll":
		Exploration.show_scroll(self, pickup)
		return
	if pickup["kind"]=="rack":
		_show_slot("blade")
		return
	if pickup["kind"]=="manual":
		_show_techniques()
		return
	if pickup["kind"]=="portal":
		_depart()
		return
	if pickup["kind"]=="forge":
		_show_equipment()
		return
	if pickup["kind"]=="bed":
		if journey_started:
			ui.toast("已经出发 · 战斗中无法休整")
		else:
			hp=max_hp
			energy=100
			_queue_feedback("休整完毕",Color("a4c6aa"))
		return
	pickup["used"]=true
	pickup["node"].hide()
	match pickup["kind"]:
		"supply":
			hp = minf(max_hp, hp + max_hp * 0.3)
			energy = minf(100, energy + 40)
			run_ash += 20
			_queue_feedback("补给 · 气血与灯火恢复", Color("9bd0a0"))
		"restore_name":
			restored_names+=1
			shield_hp=minf(60,shield_hp+15)
			state="story"
			ui.show_modal("把名字还给人","差使核过两份家书：同名的死者，不是眼前的孩子。\n纸上的错名划去，人终于敢抬头说：这不是我的愿。\n护盾 +15。",[{"id":"begin","label":"收好归名凭据"}],"已辨错契 %d / 2"%restored_names)
		"voice":
			_hear_final_voice(int(pickup["id"]),false)
		"anchor":
			anchored_lights+=1
			study_points+=1
			shield_hp=minf(60,shield_hp+15)
			state="story"
			ui.show_modal("归灯不灭","裂隙里的声音说：我没有求长生。我只想回去，替孩子把门打开。\n你稳住归灯，灯丝不再往山下抽去。\n学习点 +1，护盾 +15。",[{"id":"begin","label":"让归路亮着"}],"已稳归灯 %d / 2"%anchored_lights)
		"mengpo":
			state="story"
			ui.show_modal("孟婆 · 茶未凉","汤只解旧痛，不替人选归处。寄名摊的老人想留住女儿的名字，回声渡的行客只想睡一个安稳觉。替他们把愿望听完吧。\n\n遇见亡魂时靠近交互，两种选择各有所得，都不影响迎战首领。",[{"id":"begin","label":"记下她的话"}],"忘川旧市")
		"memory":
			memory_id=pickup["id"]
			state="memory_choice"
			ui.show_modal("亡魂 · 借一盏灯","他捧着一封没有署名的家书：我怕忘了她，也怕永远停在失去她的那天。\n\n你愿意怎样陪我走一段？",[{"id":"memory_keep","label":"留名 · 陪他记起","detail":"学习点 +1，护盾 +20"},{"id":"memory_release","label":"放下 · 尊重他的释怀","detail":"学习点 +1，气血 +25、灯火 +20"}],"两种选择都能让他前行")
		"rescue":
			world.wake_worshippers(pickup["id"])
			rescued+=1
			study_points+=1
			hp=minf(max_hp,hp+20)
			state="story"
			ui.show_modal("愿醒之人","求愿者：我想再听见她的声音，却不想永远忘记她已经离开。\n\n你替他解开愿签。学习点 +1，气血 +20。\n愿意醒来，也可以是一个愿望。",[{"id":"begin","label":"让他自行离开"}],"已唤醒 %d / 2"%rescued)
		"chest":
			run_ash+=20
			_show_boons("chest")
		"story":
			story_found.append(pickup["id"])
			state="story"
			var fragment: String="师父的灯签：去听愿祠。莲纹属于三圣母，可此处的愿境不是她所允诺。缚舟曾问我，灯能否照见归人。我没有回答。如今这沉默，也成了一根锁人的绳。" if pickup["id"]==3 else "船夫旧信：洪水那夜，他救过满船的人，却把接女儿的约定推到了下一趟。船回来了，岸却没了。后来有人许他：只要渡口无人离开，失散的人总会回来。他便把船绳结成了锁。"
			if chapter==2:
				fragment="庙祝愿簿：灾后第一年，百愿娘娘替人收殓亡者；第二年，她收走噩梦；第三年，连悲伤、失望与拒绝都写进愿契。末行被朱砂涂去——离开的念头。香客仍在叩首，却已忘记自己求的是什么。" if pickup["id"]==3 else "陆照川手札：三圣母的灯本为照路，我却用它留人。我替她续过灯芯，知道愿契收走了什么。可那孩子的命也系在灯中……我总说等修好灯就放手，却一天也不敢让灯熄灭。"
			if chapter==3: fragment=ChapterThree.FRAGMENTS[pickup["id"]]
			if chapter==4: fragment=ChapterFour.FRAGMENTS[pickup["id"]]
			if chapter==5: fragment=ChapterFive.FRAGMENTS[pickup["id"]]
			if chapter==6: fragment=ChapterSix.FRAGMENTS[pickup["id"]]
			ui.show_modal("灯中残页",fragment,[{"id":"begin","label":"收好残页"}],"主线碎片 %d / 2"%story_found.size())
		"heal":
			hp=minf(max_hp,hp+45)
			energy=minf(100,energy+30)
			ui.toast("清露入灯 · 回复 45 生命与 30 灯火")

func _show_techniques() -> void:
	if journey_started: return
	state="techniques"
	ui.show_modal("武学搭配", "兵器、普攻套路、三招技能、绝技、两部心法都可独立选择。\n技能本局学习，最多三招，修为 3 / 5 开放第二 / 第三招。",[
		{"id":"arts","label":"普攻套路 · "+Techniques.ARTS[normal_art]["name"],"detail":"4 种通用套路，任何兵器可用"},
		{"id":"skills","label":"技能 · 已学 %d / 3"%learned_skills.size(),"detail":"12 招可选 · 学习、升级或替换一招"},
		{"id":"ultimates","label":"绝技 · "+Techniques.ULTIMATES[ultimate_id]["name"],"detail":"10 种绝技 · 独立满战意释放"},
		{"id":"minds","label":"心法 · 已装 %d / 2"%passives.size(),"detail":"10 部通用心法 · 先卸下再更换"},
		{"id":"boonbook","label":"残愿图鉴 · 32 种","detail":"查看本局叠加与全部效果"},
		{"id":"resume","label":"继续"}],"自由组合")

func _skill_capacity() -> int:
	return 1 if not journey_started else 1+int(level>=3)+int(level>=5)

func _show_skills() -> void:
	state="skills"
	var buttons: Array=[]
	for slot in range(3):
		var learned: bool=slot<learned_skills.size()
		var label: String=("第 %d 招 · "%[slot+1])+(Techniques.SKILLS[learned_skills[slot]]["name"]+" · %d 级"%skill_ranks.get(learned_skills[slot],1) if learned else "尚未学习")
		buttons.append({"id":"study_"+str(slot),"label":label,"detail":"升级或替换这一招" if learned else ("点击学习一招" if slot<_skill_capacity() else "修为 %d 开放"%(3 if slot==1 else 5)),"disabled":slot>=_skill_capacity()})
	buttons.append({"id":"techniques","label":"其他武学"})
	buttons.append({"id":"resume","label":"继续"})
	ui.show_modal("三招技能", "本局学习点 %d · 每次升级修为获得 1 点\n学习、升级或替换均处理一招。技能最多 5 级，死亡清零。\n在家可免费选择第一招；传送出发后按本局学习点成长。"%study_points,buttons,"逐招学习")

func _show_learning(slot: int) -> void:
	if slot<0 or slot>=_skill_capacity() or slot>learned_skills.size():
		ui.toast("第二招修为 3 开放，第三招修为 5 开放")
		return
	learning_slot=slot
	state="learning"
	var buttons: Array=[]
	var existing: String=learned_skills[slot] if slot<learned_skills.size() else ""
	var can_pay: bool=not journey_started or study_points>0
	if existing!="":
		var rank: int=skill_ranks.get(existing,1)
		buttons.append({"id":"rank_skill","label":"升级 "+Techniques.SKILLS[existing]["name"]+" · %d → %d"%[rank,mini(5,rank+1)],"detail":"消耗 1 学习点，提高伤害、防护或持续时间","disabled":not journey_started or study_points<=0 or rank>=5})
	for id in Techniques.SKILLS:
		if id in learned_skills: continue
		buttons.append({"id":"learn_"+id,"label":("替换为 " if existing!="" else "学习 ")+Techniques.SKILLS[id]["name"],"detail":Techniques.SKILLS[id]["desc"],"disabled":not can_pay})
	buttons.append({"id":"skills","label":"返回三招技能"})
	buttons.append({"id":"resume","label":"暂不学习"})
	ui.show_modal("第 %d 招"%(slot+1),"每次只选一招 · 任何兵器均可使用\n"+("家中免费选第一招" if not journey_started else "学习点 %d · 替换后新招从 1 级开始"%study_points),buttons,"学习与替换")

func _learn_skill(id: String) -> void:
	if state!="learning" or id not in Techniques.SKILLS or id in learned_skills: return
	if journey_started and study_points<=0: return
	if learning_slot>=_skill_capacity() or learning_slot>learned_skills.size(): return
	if journey_started: study_points-=1
	if learning_slot<learned_skills.size():
		skill_ranks.erase(learned_skills[learning_slot])
		learned_skills[learning_slot]=id
	else: learned_skills.append(id)
	skill_ranks[id]=1
	skill_cds[learning_slot]=maxf(skill_cds[learning_slot],0.5)
	active_skill=id
	_queue_feedback("学会 · "+Techniques.SKILLS[id]["name"],Color(Techniques.SKILLS[id]["color"]))
	_refresh_gear_visual()
	_show_skills()

func _show_catalog(kind: String) -> void:
	state=kind
	var buttons: Array=[]
	var catalog: Dictionary={"arts":Techniques.ARTS,"ultimates":Techniques.ULTIMATES,"minds":Techniques.MINDS}[kind]
	for id in catalog:
		var selected: bool=(id==normal_art if kind=="arts" else (id==ultimate_id if kind=="ultimates" else id in passives))
		buttons.append({"id":"choose_"+kind+"_"+id,"label":catalog[id]["name"]+(" · 已装" if selected else " · 选择"),"detail":catalog[id]["desc"],"disabled":selected and kind!="minds"})
	buttons.append({"id":"techniques","label":"返回武学"})
	buttons.append({"id":"resume","label":"继续"})
	ui.show_modal({"arts":"普攻套路","ultimates":"十式绝技","minds":"十部心法"}[kind],"所有兵器通用。"+("最多装两部；点已装心法卸下。" if kind=="minds" else "独立选择，不改变已学技能。"),buttons,"自由搭配")

func _tick_waves(dt: float) -> void:
	if not journey_started: return
	wave_clock-=dt
	if wave_clock<=0:
		for old_enemy in enemies.duplicate():
			if old_enemy.get("wave",false) and old_enemy["node"].position.distance_to(player.position)>32:
				if is_instance_valid(old_enemy["tell"]): old_enemy["tell"].queue_free()
				old_enemy["node"].queue_free()
				enemies.erase(old_enemy)
		wave_clock=maxf(4.0,6.0-run_seconds/180.0)
		wave_number+=1
		var count: int=roundi(roundi(mini(14,7+int(run_seconds/30))*wave_density)*swarm_multiplier)
		var power: float=pow(wave_growth,wave_number-1)*pow(1.20,stage_depth-1)
		for i in range(count):
			if enemies.size()>=65: break
			var angle: float=rng.randf_range(0,TAU)
			var spawn_pos: Vector3=world.constrain_position(player.position+Vector3(sin(angle),0,cos(angle))*rng.randf_range(10,14))
			if spawn_pos.distance_to(player.position)<8:
				spawn_pos=world.constrain_position(player.position+(Vector3.ZERO-player.position).normalized()*12)
			var kind: String="grunt"
			if run_seconds>45 and i%4==0: kind="ranger"
			if run_seconds>120 and i==count-1: kind="brute"
			var enemy: Dictionary=_spawn_enemy(kind,spawn_pos)
			enemy["wave"]=true
			enemy["power"]=power
			enemy["hp"]*=power
			enemy["max_hp"]*=power
			enemy["speed"]*=minf(1.25,1.0+run_seconds/900.0)
			if i%5==0 and kind=="grunt": enemy["speed"]*=1.25
	if not boss_spawned and (level>=stage_entry_level+6 or stage_seconds>=360): _spawn_boss()

func _spawn_boss() -> void:
	if boss_spawned: return
	boss_spawned=true
	var boss: Dictionary=_spawn_enemy("boss",world.landmarks[6]["pos"])
	boss["power"]=pow(1.2,stage_depth-1)
	ui.toast(_boss_name()+"现身 · 前往小地图的朱砂点，击败首领通关")

func _tick_orbit(dt: float) -> void:
	if _boon("orbit")==0 and "orbit" not in passives: return
	orbit_clock-=dt
	if orbit_clock>0: return
	orbit_clock=0.55
	for i in range(2):
		var angle: float=run_seconds*2.4+i*PI
		var pos: Vector3=player.position+Vector3(sin(angle),0,cos(angle))*2.3
		_ring(pos,0.65,Color("39453b"),0.5)
		for enemy in enemies.duplicate():
			if enemy["hp"]>0 and enemy["node"].position.distance_to(pos)<1.6:
				_damage_enemy(enemy,(14 if "orbit" in passives else 5)+6*_boon("orbit"),player.position)
				if state!="playing": return
				energy=minf(100,energy+3)

func _autoplay_test() -> void:
	set_process(false)
	var builds: Dictionary={
		"flame":{"blade":"iron_staff","robe":"sage_robe","lamp":"ember_lamp","art":"sweep","minds":["orbit","reservoir"],"skills":["fire","vortex","thunder"],"ultimate":"lotus"},
		"control":{"blade":"long_spear","robe":"wind_robe","lamp":"frost_lamp","art":"thrust","minds":["focus","swift"],"skills":["frost","stun","darts"],"ultimate":"blizzard"},
		"sustain":{"blade":"long_sword","robe":"iron_robe","lamp":"ward_lamp","art":"flurry","minds":["leech","ironwall"],"skills":["weak","heal","barrier"],"ultimate":"sanctuary"},
		"burst":{"blade":"heavy_cleaver","robe":"crimson_robe","lamp":"broken_lamp","art":"cleave","minds":["spark","fury"],"skills":["fire","quake","haste"],"ultimate":"avatar"}
	}
	var build_id: String="flame"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--build="): build_id=arg.get_slice("=",1)
	var build: Dictionary=builds[build_id]
	var casts: Dictionary={}
	var ultimate_casts: int=0
	var level_times: Array=[]
	var stage_results: Array=[]
	var observed_level: int=1
	var final_snapshot: Dictionary={}
	var seed_value: int=4523
	var samples: int=0
	var nearby_sum: int=0
	var peak: int=0
	var empty_samples: int=0
	var early_samples: int=0
	var early_sum: int=0
	var early_empty: int=0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--growth="): wave_growth=float(arg.get_slice("=",1))
		if arg.begins_with("--swarm="): swarm_multiplier=float(arg.get_slice("=",1))
		if arg.begins_with("--density="): wave_density=float(arg.get_slice("=",1))
		if arg.begins_with("--seed="): seed_value=int(arg.get_slice("=",1))
	rng.seed=seed_value
	legacy={"coins":30,"heart":0,"weapon":0,"spirit":0,"chapter":1}
	_start_run()
	_on_action("begin")
	progress["equipped"]={"blade":build["blade"],"robe":build["robe"],"lamp":build["lamp"]}
	normal_art=build["art"]
	passives.assign(build["minds"])
	ultimate_id=build["ultimate"]
	_show_learning(0)
	_learn_skill(build["skills"][0])
	_on_action("resume")
	_depart()
	if "--chapter2" in OS.get_cmdline_user_args():
		chapter=2
		_start_expedition()
	Input.action_press("attack")
	for frame in range(60*480):
		if state=="result": break
		if level>observed_level:
			level_times.append({"level":level,"seconds":snappedf(run_seconds,0.1),"wave":wave_number})
			observed_level=level
		final_snapshot={"state":state,"stage":stage_depth,"boss_spawned":boss_spawned,"seconds":snappedf(run_seconds,0.1),"level":level,"kills":kills,"hp":snappedf(hp,0.1),"wave":wave_number,"ranks":skill_ranks.duplicate(),"boons":boon_counts.duplicate()}
		final_snapshot["damage_sources"] = damage_sources.duplicate(true)
		final_snapshot["last_damage_source"] = last_damage_source
		if state=="transition":
			stage_results.append(final_snapshot.duplicate(true))
			if stage_depth>=2:
				print("CAMPAIGN_AUTOPLAY_CLEAR ",stage_depth," stages, level=",level," seconds=",run_seconds)
				_on_action("cash_out")
			else: _on_action("continue_stage")
		elif state=="dying":
			break
		elif state=="story": _on_action("begin")
		elif state=="learning":
			if learning_slot<learned_skills.size():
				_on_action("rank_skill")
			else:
				for id in build["skills"]:
					if id not in learned_skills:
						_learn_skill(id)
						break
			_on_action("resume")
		elif state=="skills":
			if study_points>0:
				if learned_skills.size()<_skill_capacity(): _show_learning(learned_skills.size())
				else:
					var slot: int=-1
					for i in range(learned_skills.size()):
						if skill_ranks.get(learned_skills[i],1)<5:
							slot=i
							break
					if slot>=0: _show_learning(slot)
					else: _on_action("resume")
			else: _on_action("resume")
		elif state=="boon":
			var index: int=0
			for i in range(choices.size()):
				if choices[i]["id"] in ["drain","orbit","health","crit"]: index=i
			_take_boon(index)
		elif state=="playing":
			if frame%30==0:
				var nearby: int=0
				for enemy in enemies:
					if enemy["node"].position.distance_to(player.position)<8: nearby+=1
				if run_seconds<=60:
					early_samples+=1
					early_sum+=nearby
					if nearby==0: early_empty+=1
				samples+=1
				nearby_sum+=nearby
				peak=maxi(peak,enemies.size())
				if nearby==0: empty_samples+=1
			var direction: Vector3=Vector3.ZERO
			var target: Dictionary=_nearest_enemy(80)
			if boss_spawned:
				for enemy in enemies:
					if enemy["kind"]=="boss": target=enemy
			if not target.is_empty():
				var diff: Vector3=target["node"].position-player.position
				var toward: Vector3=diff.normalized()
				direction=toward if diff.length()>2.4 else Vector3(-toward.z,0,toward.x)
			for enemy in enemies:
				if enemy["mode"]=="tell" and enemy["attack"] not in ["shot","volley"]:
					var away: Vector3=player.position-enemy["target"]
					if away.length()<float(enemy["attack_radius"])+0.8:
						direction=away.normalized() if away.length()>0.1 else Vector3.RIGHT
						if enemy["timer"]<0.6: _dash(direction)
			ui.move_vector=Vector2(direction.x,direction.z)
			if not _nearest_enemy(8).is_empty():
				for i in range(learned_skills.size()):
					var id: String=learned_skills[i]
					if id=="heal" and hp>max_hp*0.7: continue
					if skill_cds[i]>0: continue
					if id not in ["barrier","haste","heal","thunder","darts"]:
						var cast_radius: float=(6.5 if id in ["vortex","quake","weak"] else 5.0)*(1+0.1*_boon("flame"))
						if _nearest_enemy(cast_radius).is_empty(): continue
					_cast_skill(i)
					if skill_cds[i]>0: casts[id]=int(casts.get(id,0))+1
				if ultimate_charge>=100 and (ultimate_id!="sanctuary" or hp<max_hp*0.7):
					_ultimate()
					if ultimate_charge<100: ultimate_casts+=1
			if state=="playing": _tick_game(1.0/60.0)
		if frame%30==0: await get_tree().process_frame
	Input.action_release("attack")
	ui.move_vector=Vector2.ZERO
	print("BALANCE_RESULT ",JSON.stringify({"seed":seed_value,"build":build_id,"minds":build["minds"],"casts":casts,"ultimates":ultimate_casts,"levels":level_times,"stages":stage_results,"final":final_snapshot,"growth":wave_growth,"nearby_mean":float(nearby_sum)/maxi(1,samples),"early_nearby":float(early_sum)/maxi(1,early_samples),"peak":peak,"empty_fraction":float(empty_samples)/maxi(1,samples)}))
	print("DENSITY_RESULT ",JSON.stringify({"seed":seed_value,"swarm":swarm_multiplier,"growth":wave_growth,"early_nearby":float(early_sum)/maxi(1,early_samples),"early_empty":float(early_empty)/maxi(1,early_samples),"density":wave_density,"nearby_mean":float(nearby_sum)/maxi(1,samples),"peak":peak,"empty_fraction":float(empty_samples)/maxi(1,samples),"result":last_result}))
	print("AUTOPLAY_04 ",last_result," returned_home=",not journey_started)
	get_tree().quit(0 if last_result.get("victory",false) else 1)

func _material(color: Color, emission: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission:
		mat.emission_enabled = true
		mat.emission = color
	return mat

func _disc(pos: Vector3, radius: float, color: Color, parent: Node3D = null) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.025
	mesh.radial_segments = 64
	node.mesh = mesh
	node.material_override = _material(color)
	(parent if parent else effects).add_child(node)
	node.position = Vector3(pos.x, 0.065, pos.z)
	return node

func _ring(pos: Vector3, radius: float, color: Color, duration: float, parent: Node3D = null) -> Node3D:
	var node := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(0.01, radius - 0.065)
	torus.outer_radius = radius + 0.065
	torus.rings = 48
	torus.ring_segments = 6
	node.mesh = torus
	node.material_override = _material(color, true)
	(parent if parent else effects).add_child(node)
	node.position = Vector3(pos.x, 0.12, pos.z)
	if duration > 0:
		node.scale = Vector3(0.3, 0.3, 0.3)
		var tween := create_tween().set_parallel()
		tween.tween_property(node, "scale", Vector3.ONE, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(node.material_override, "albedo_color:a", 0.0, duration)
		tween.chain().tween_callback(node.queue_free)
	return node

func _arc(pos: Vector3, direction: Vector3, radius: float, color: Color) -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var center_angle: float = atan2(direction.x, direction.z)
	for i in range(18):
		var a: float = center_angle - 1.5 + i * 3.0 / 18
		var b: float = center_angle - 1.5 + (i + 1) * 3.0 / 18
		var points: Array[Vector3] = [Vector3(sin(a),0,cos(a))*radius,Vector3(sin(b),0,cos(b))*radius,Vector3(sin(a),0,cos(a))*(radius-0.22),Vector3(sin(b),0,cos(b))*radius,Vector3(sin(b),0,cos(b))*(radius-0.22),Vector3(sin(a),0,cos(a))*(radius-0.22)]
		for point in points: mesh.surface_add_vertex(point)
	mesh.surface_end()
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _material(color, true)
	effects.add_child(node)
	node.position = pos
	var tween := create_tween()
	tween.tween_property(node.material_override, "albedo_color:a", 0.0, 0.2)
	tween.tween_callback(node.queue_free)

func _float_text(pos: Vector3, text: String, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 42
	label.pixel_size = 0.008
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	effects.add_child(label)
	label.position = pos
	var tween := create_tween().set_parallel()
	tween.tween_property(label, "position:y", pos.y + 1.2, 0.65)
	tween.tween_property(label, "modulate:a", 0.0, 0.65)
	tween.chain().tween_callback(label.queue_free)

func _tone(frequency: float, length: float, volume: float) -> void:
	if muted or test_mode: return
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = 22050
	var data := PackedByteArray()
	var count: int = int(22050 * length)
	data.resize(count * 2)
	for i in range(count):
		var t: float = float(i) / 22050
		var env: float = pow(1 - float(i) / count, 2)
		var value: float = (sin(TAU * frequency * t * (1 - t * 0.8)) * 0.7 + sin(TAU * frequency * 2.01 * t) * 0.3) * env * volume
		data.encode_s16(i * 2, int(value * 32000))
	audio.data = data
	sound_player.stream = audio
	sound_player.play()

func _start_capture() -> void:
	await get_tree().create_timer(0.25).timeout
	state="capture"
	player.visible=true
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/手机布局预览.png"))
	state="playing"
	_show_learning(0)
	_learn_skill("frost")
	_on_action("resume")
	_depart()
	level=5
	learned_skills=["frost","thunder","barrier"]
	skill_ranks={"frost":1,"thunder":1,"barrier":1}
	for i in range(14): _spawn_enemy("grunt",player.position+Vector3(cos(i*0.48),0,sin(i*0.48))*(3.0+i%3))
	energy=100
	_cast_skill(0)
	ultimate_charge=100
	state="capture"
	player.visible=true
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/战斗预览.png"))
	_show_catalog("ultimates")
	await get_tree().create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/绝技选择预览.png"))
	chapter=2
	_start_expedition()
	state="capture"
	player.position=world.landmarks[6]["pos"]+Vector3(0,0,3)
	camera.position=player.position+Vector3(0,22,18)
	camera.look_at(player.position)
	_spawn_boss()
	_spawn_blessing(player.position+Vector3(-3,0,0))
	ui.hide_modal()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/听愿祠预览.png"))
	ui.show_audio(music_volume,sfx_volume)
	await get_tree().create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/声音设置预览.png"))
	print("CAPTURE_OK")
	get_tree().quit()

func _smoke_test() -> void:
	await _mobile_test()

func _visible_map_points() -> Array:
	var result: Array=[]
	for item in world.landmarks:
		if item["id"]==6:
			if boss_spawned: result.append(item)
		elif item["visited"]: result.append(item)
	return result

func _depart() -> void:
	if journey_started: return
	if learned_skills.is_empty():
		ui.toast("先学第一招，再从传送阵出发")
		_show_learning(0)
		return
	chapter=1
	_start_expedition()

func _tutorial_prompt() -> String:
	if not tutorial_flags.get("move",false): return "① 拖动左下摇杆，在竹林院落走动"
	if not tutorial_flags.get("loadout",false): return "② 点右上兵器，或靠近左边兵器架领取"
	if learned_skills.is_empty(): return "③ 点右上武学 → 学习第一招"
	if not tutorial_flags.get("attack",false): return "④ 靠近木桩，按住右下普攻试招"
	if not tutorial_flags.get("skill",false): return "⑤ 点右侧技能试招，再练习踏影闪避"
	return "准备好了 · 走到右侧莲纹传送阵，点传送"

func _queue_feedback(message: String, color: Color) -> void:
	feedback_pending=message
	feedback_color=color
	ui.toast(message+" · 继续探索后查看效果")

func _growth_burst(message: String,color: Color) -> void:
	_ring(player.position,2.8,color,0.65)
	_ring(player.position,1.5,Color("f5e6be"),0.9)
	_burst(player.position+Vector3.UP*0.4,color,16,2.3)
	_float_text(player.position+Vector3.UP*2.4,message,color)
	_sfx("impactBell_heavy_000.ogg",-17)
	_refresh_gear_visual()

func _burst(pos: Vector3,color: Color,count: int,spread: float) -> void:
	if effects.get_child_count()>180: return
	for i in range(count if quality!="low" else mini(count,5)):
		var sprite:=Sprite3D.new()
		sprite.texture=load("res://assets/kenney/spark_01.png")
		sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		sprite.no_depth_test=false
		sprite.pixel_size=0.003
		sprite.modulate=color
		effects.add_child(sprite)
		sprite.position=pos
		sprite.scale=Vector3.ONE*cosmetic_rng.randf_range(0.16,0.35)
		var drift:=Vector3(cosmetic_rng.randf_range(-1,1),cosmetic_rng.randf_range(0.2,1.5),cosmetic_rng.randf_range(-1,1))*spread
		var tween:=create_tween().set_parallel()
		tween.tween_property(sprite,"position",pos+drift,0.38)
		tween.tween_property(sprite,"modulate:a",0.0,0.38)
		tween.chain().tween_callback(sprite.queue_free)

func _bolt(a: Vector3,b: Vector3,color: Color) -> void:
	var beam: MeshInstance3D=world._beam(effects,a,b,0.055,color)
	beam.material_override=_material(color,true)
	var tween:=create_tween()
	tween.tween_property(beam,"scale",Vector3(0.01,1,0.01),0.20)
	tween.tween_callback(beam.queue_free)

func _chain_lightning(count: int,damage: float) -> void:
	var previous: Vector3=player.position
	var struck: Array=[]
	for i in range(count):
		var best: Dictionary={}
		var distance: float=8.0 if i==0 else 4.0
		for enemy in enemies:
			if enemy in struck or enemy["hp"]<=0: continue
			var d: float=previous.distance_to(enemy["node"].position)
			if d<distance:
				distance=d
				best=enemy
		if best.is_empty(): break
		struck.append(best)
		var end: Vector3=best["node"].position
		_bolt(previous+Vector3.UP,end+Vector3.UP,Color("bcb2f0"))
		_damage_enemy(best,damage,player.position)
		if state!="playing": return
		previous=end

func _sfx(file: String,volume: float) -> void:
	if muted or test_mode or sfx_players.is_empty(): return
	var voice: AudioStreamPlayer=sfx_players[sfx_index%sfx_players.size()]
	sfx_index+=1
	voice.stream=load("res://assets/kenney/"+file)
	voice.volume_db=volume
	voice.pitch_scale=cosmetic_rng.randf_range(0.93,1.07)
	voice.play()

func _refresh_gear_visual() -> void:
	if not is_instance_valid(player): return
	preload("res://scripts/model_library.gd").equip(player,progress["equipped"]["blade"])
	var old: Node=player.get_node_or_null("LoadoutAura")
	if old: old.free()
	var aura:=Node3D.new()
	aura.name="LoadoutAura"
	player.add_child(aura)
	var robe: String=progress["equipped"]["robe"]
	var cloth_color:=Color(Arsenal.ROBES[robe]["color"])
	preload("res://scripts/model_library.gd").robe(player,cloth_color)
	var robe_mark:=Sprite3D.new()
	robe_mark.texture=load("res://assets/ui/"+{"pilgrim_robe":"heal","iron_robe":"barrier","wind_robe":"haste","crimson_robe":"attack","sage_robe":"darts","lotus_robe":"ultimate"}[robe]+".svg")
	robe_mark.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	robe_mark.pixel_size=0.004
	robe_mark.modulate=cloth_color
	robe_mark.position=Vector3(0,0.8,0.42)
	aura.add_child(robe_mark)
	var lamp: String=progress["equipped"]["lamp"]
	var lamp_color:=Color(Arsenal.LAMPS[lamp]["color"])
	var orb:=Node3D.new()
	orb.name="SpiritOrb"
	orb.position=Vector3(-0.9,1.5,0.15)
	aura.add_child(orb)
	world._sphere(orb,Vector3.ZERO,0.18,lamp_color,12,0.8)
	var glyph:=Sprite3D.new()
	glyph.texture=load("res://assets/ui/"+Arsenal.LAMPS[lamp]["icon"]+".svg")
	glyph.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	glyph.pixel_size=0.007
	glyph.modulate=lamp_color
	orb.add_child(glyph)
	for i in range(Arsenal.LAMPS.keys().find(lamp)+1):
		var a: float=i*TAU/float(Arsenal.LAMPS.keys().find(lamp)+1)
		world._sphere(orb,Vector3(cos(a)*0.32,0,sin(a)*0.32),0.04,lamp_color,6)
	var color:=Color(Techniques.SKILLS[active_skill]["color"])
	var seal:=Sprite3D.new()
	seal.texture=load("res://assets/kenney/magic_01.png")
	seal.rotation.x=-PI/2
	seal.pixel_size=0.0045
	seal.position.y=0.05
	seal.modulate=Color(color,0.40)
	aura.add_child(seal)
	var status:=Sprite3D.new()
	status.name="StatusSeal"
	status.texture=load("res://assets/kenney/magic_01.png")
	status.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	status.position.y=1.0
	status.pixel_size=0.004
	status.modulate=Color("e6ce8f") if guard_left>0 or shield_hp>0 else (Color("a4e1be") if haste_left>0 else Color("eb9765"))
	status.visible=guard_left>0 or haste_left>0 or avatar_left>0 or shield_hp>0
	aura.add_child(status)
	var mind_icons: Dictionary={"orbit":"ultimate","spark":"thunder","leech":"heal","momentum":"dash","ironwall":"barrier","swift":"haste","reservoir":"vortex","fury":"attack","merciful":"frost","focus":"stun"}
	for i in range(passives.size()):
		var charm:=Sprite3D.new()
		charm.texture=load("res://assets/ui/"+mind_icons[passives[i]]+".svg")
		charm.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		charm.pixel_size=0.005
		charm.position=Vector3(-0.7+i*1.4,1.4,0)
		charm.modulate=Color("cfb47c") if i==0 else Color("9fc1af")
		aura.add_child(charm)


func _load_legacy(path: String=LEGACY_PATH) -> void:
	if (test_mode or capture_mode) and path==LEGACY_PATH: return
	legacy=ProfileStore.load_profile(path)

func _save_legacy(path: String=LEGACY_PATH) -> void:
	if (test_mode or capture_mode) and path==LEGACY_PATH: return
	if ProfileStore.save_profile(legacy,path)!=OK:
		ui.toast("保存失败 · 请检查手机存储空间")

func _show_legacy() -> void:
	state="legacy"
	var buttons: Array=[]
	for key in ["heart","weapon","spirit"]:
		var rank: int=legacy[key]
		buttons.append({"id":"legacy_"+key,"label":{ "heart":"长春养气诀","weapon":"百兵淬锋诀","spirit":"莲心归元诀"}[key]+" · %d / 5"%rank,"detail":{"heart":"每级初始气血 +8","weapon":"每级所有兵器基础伤害 +2","spirit":"每级起始灯火 +10"}[key]+("\n已圆满" if rank>=5 else "\n修习需要 %d 香火钱"%(20+rank*15)),"disabled":rank>=5 or legacy["coins"]<20+rank*15})
	buttons.append({"id":"equipment","label":"返回行囊"})
	ui.show_modal("家传根基","香火钱 %d · 修习后永久保留\n击败敌人后结束行程可得香火钱，通关另有奖励。\n兵器、普攻、绝技与心法独立搭配；三招技能每局重新学习。"%legacy["coins"],buttons,"残灯庵 · 修习")


func _revision_test() -> void:
	await _mobile_test()

func _test_clear_enemies() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy["tell"]): enemy["tell"].free()
		enemy["node"].free()
	enemies.clear()

func _tick_buffs(dt: float) -> void:
	guard_left=maxf(0,guard_left-dt)
	haste_left=maxf(0,haste_left-dt)
	avatar_left=maxf(0,avatar_left-dt)
	if "reservoir" in passives: energy=minf(100,energy+2*dt)
	if not journey_started: energy=minf(100,energy+12*dt)
	shield_clock-=dt
	if shield_clock<=0:
		shield_clock=12.0
		if progress["equipped"]["robe"]=="lotus_robe": shield_hp=maxf(shield_hp,15)
		if _boon("shield")>0:
			shield_hp=maxf(shield_hp,10.0*_boon("shield"))
			_ring(player.position,1.4,Color("ddce96"),0.5)
	var aura: Node3D=player.get_node_or_null("LoadoutAura")
	if aura:
		var orb: Node3D=aura.get_node_or_null("SpiritOrb")
		if orb:
			orb.position=orb.position.lerp(Vector3(-0.9,1.5+sin(start_time*2.5)*0.15,0.15),minf(1,dt*8))
			orb.rotation.y+=dt
		var seal: Node3D=aura.get_node_or_null("StatusSeal")
		if seal:
			seal.visible=guard_left>0 or haste_left>0 or avatar_left>0 or shield_hp>0
			seal.scale=Vector3.ONE*(1.0+sin(start_time*4)*0.08)

func _ultimate() -> void:
	if state!="playing" or ultimate_cd>0: return
	if ultimate_charge<100:
		ui.toast("绝技需满战意 · 命中和击败敌人可积攒")
		return
	ultimate_charge=0
	ultimate_cd=2.0
	var id: String=ultimate_id
	var color:=Color(Techniques.ULTIMATES[id]["color"])
	var power: float=1+0.2*_boon("overload")
	var origin: Vector3=player.position
	_ring(origin,10.0,color,0.75)
	_burst(origin+Vector3.UP,color,18,4)
	shake=0.4
	if id=="sanctuary":
		hp=minf(max_hp,hp+max_hp*0.35)
		shield_hp+=65*power
		guard_left=7.0
	elif id=="avatar": avatar_left=8.0
	elif id=="tempest": _chain_lightning(16,115.0*power)
	if id=="sword_rain":
		var target: Dictionary=_nearest_enemy(14)
		if not target.is_empty(): facing=(target["node"].position-origin).normalized()
		for i in range(9):
			var end: Vector3=origin+facing.rotated(Vector3.UP,(i-4)*0.17)*14
			_bolt(end+Vector3.UP*5,end,color)
	elif id=="hurricane":
		for i in range(5): _arc(origin+Vector3.UP*(i*0.5),Vector3(cos(i),0,sin(i)),9-i,color)
	elif id=="blizzard":
		for i in range(12):
			var pos: Vector3=origin+Vector3(cos(i*TAU/12),0,sin(i*TAU/12))*6
			_bolt(pos,pos+Vector3.UP*3,color)
	elif id=="void":
		for i in range(3): _ring(origin,8-i*2,Color("654369"),0.5+i*0.1)
	for enemy in enemies.duplicate():
		var diff: Vector3=enemy["node"].position-origin
		if id=="sword_rain":
			if diff.length()>14 or diff.normalized().dot(facing)<0.6: continue
		elif diff.length()>10: continue
		if id in ["lotus","meteor"]: enemy["burn"]=6.0
		if id=="tempest": enemy["stun"]=0.4 if enemy["kind"]=="boss" else 1.0
		if id=="blizzard":
			enemy["slow"]=7.0
			enemy["stun"]=0.5 if enemy["kind"]=="boss" else 2.0
		if id=="venom":
			enemy["poison"]=8.0
			enemy["weak"]=8.0
		if id=="hurricane":
			enemy["exposed"]=6.0
			if enemy["kind"]!="boss": enemy["node"].position=world.constrain_position(origin+diff.normalized()*2.1)
		if id=="sanctuary" and enemy["kind"]!="boss": enemy["node"].position=world.constrain_position(enemy["node"].position+diff.normalized()*4)
		if id=="meteor":
			_bolt(enemy["node"].position+Vector3.UP*6,enemy["node"].position,color)
			_ring(enemy["node"].position,1.8,color,0.5)
		var amount: float={"lotus":140.0,"tempest":0.0,"sanctuary":50.0,"blizzard":105.0,"hurricane":100.0,"sword_rain":175.0,"venom":85.0,"avatar":0.0,"void":170.0,"meteor":150.0}[id]
		if id=="void" and enemy["kind"]!="boss" and enemy["hp"]<enemy["max_hp"]*0.3: amount=maxf(amount,enemy["hp"])
		if amount>0: _damage_enemy(enemy,amount*power,origin)
		if state!="playing": return
	_refresh_gear_visual()
	_float_text(origin+Vector3.UP*2.5,Techniques.ULTIMATES[id]["name"],color)
	_sfx("impactBell_heavy_000.ogg",-13)

func _mobile_test() -> void:
	await load("res://scripts/campaign_checks.gd").run(self)

func _setup_audio() -> void:
	for channel in ["Music","SFX"]:
		if AudioServer.get_bus_index(channel)<0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1,channel)
	sound_player.bus="SFX"
	for voice in sfx_players: voice.bus="SFX"
	music_player=AudioStreamPlayer.new()
	music_player.bus="Music"
	add_child(music_player)
	var stream: AudioStreamOggVorbis=load("res://assets/music/wish-loop.ogg")
	stream.loop=true
	music_player.stream=stream
	_load_audio()
	_apply_audio()
	ui.volume_changed.connect(_set_volume)
	if not test_mode and not capture_mode: music_player.play()

func _set_volume(channel: String,value: float) -> void:
	if channel=="music": music_volume=clampf(value,0,1)
	elif channel=="sfx": sfx_volume=clampf(value,0,1)
	_apply_audio()

func _apply_audio() -> void:
	for channel in ["Music","SFX"]:
		var value: float=music_volume if channel=="Music" else sfx_volume
		var index: int=AudioServer.get_bus_index(channel)
		AudioServer.set_bus_mute(index,value<=0)
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(0.0001,value)))

func _load_audio(path: String="user://audio.cfg") -> void:
	if (test_mode or capture_mode) and path=="user://audio.cfg": return
	var config:=ConfigFile.new()
	if config.load(path)==OK:
		music_volume=clampf(float(config.get_value("audio","music",0.35)),0,1)
		sfx_volume=clampf(float(config.get_value("audio","sfx",0.85)),0,1)

func _save_audio(path: String="user://audio.cfg") -> void:
	if (test_mode or capture_mode) and path=="user://audio.cfg": return
	var config:=ConfigFile.new()
	config.set_value("audio","music",music_volume)
	config.set_value("audio","sfx",sfx_volume)
	if config.save(path)!=OK: ui.toast("声音设置保存失败")

func _chapter_name() -> String:
	return "愿境深处 · 第%d境"%stage_depth if stage_depth>6 else {1:"雾隐渡",2:"听愿祠",3:"忘川旧市",4:"华山照影",5:"莲心台",6:"城隍夜簿"}[chapter]

func _boss_name() -> String:
	if stage_depth>6: return "余烬愿影"
	return {1:"镇渡使 · 缚舟",2:"百愿娘娘",3:"无名判影",4:"二郎显圣真君",5:"陆照川 · 守灯人",6:"百契债身"}[chapter]

func _spawn_blessing(pos: Vector3) -> void:
	if blessings.size()>=3:
		var old: Dictionary=blessings.pop_front()
		if is_instance_valid(old["node"]): old["node"].queue_free()
	var disc: MeshInstance3D=_disc(pos,3.4,Color(0.86,0.67,0.24,0.30))
	blessings.append({"node":disc,"pos":pos,"life":4.5,"warned":false})
	ui.toast("赐福：前两秒回血 · 久留定身 1.2 秒，可用踏影解缚 · 转红后炸裂，离圈避开")

func _tick_blessings(dt: float) -> void:
	var inside: bool=false
	for zone in blessings.duplicate():
		zone["life"]-=dt
		var nearby: bool=player.position.distance_to(zone["pos"])<3.4
		if zone["life"]<=0:
			var pos: Vector3=zone["pos"]
			if is_instance_valid(zone["node"]): zone["node"].queue_free()
			blessings.erase(zone)
			_ring(pos,3.4,Color("da7555"),0.35)
			if nearby: _hurt_player(24.0, "boss_blessing")
			if state!="playing": return
			continue
		if zone["life"]<=1.5 and not zone.get("warned",false):
			zone["warned"]=true
			zone["node"].material_override.albedo_color=Color(0.85,0.20,0.12,0.42)
			_float_text(zone["pos"]+Vector3.UP,"愿契将裂 · 离圈",Color("b8432e"))
		if nearby: inside=true
	if inside and dash_left<=0 and root_ward<=0:
		var healing_time: float=minf(dt,maxf(0,2.0-blessing_exposure))
		blessing_exposure+=dt
		hp=minf(max_hp,hp+8*healing_time)
		if blessing_exposure>=2 and blessing_exposure-dt<2:
			rooted_left=1.2
			dash_left=0
			_update_root_mark()
			ui.toast("愿契定身 · 踏影可解缚，仍可攻击施法")
	else: blessing_exposure=0

func _xp_requirement(at_level: int) -> int:
	return XP_STEPS[clampi(at_level-1,0,5)] if at_level<=6 else 520+(at_level-6)*140

func _cash_out() -> void:
	if state!="transition": return
	var earned: int=earned_incense+mini(kills/4,150)
	var completed: int=stage_depth
	var result: Dictionary={"victory":true,"depth":completed,"reward":earned,"seconds":run_seconds,"hits":received_hits,"damage":received_damage,"kills":kills,"level":level}
	legacy["coins"]+=earned
	_save_legacy()
	_enter_home(false)
	state="result"
	settled=true
	last_result=result
	ui.show_modal("安然归家","通关 %d 境，本次香火 %d 全部带回。\n局内成长已结算，下次出发重新准备。"%[completed,earned],[{"id":"back_home","label":"回到院中"}],"全额结算")

func _lamp_cast_effect() -> void:
	var lamp: String=progress["equipped"]["lamp"]
	var color:=Color(Arsenal.LAMPS[lamp]["color"])
	var orb: Node3D=player.get_node_or_null("LoadoutAura/SpiritOrb")
	if orb:
		orb.position=Vector3(-0.4,1.7,-0.7)
		_ring(orb.global_position,0.7,color,0.25)
	if lamp=="ward_lamp": shield_hp=minf(40,shield_hp+8)
	if lamp=="frost_lamp": _ring(player.position,5,color,0.4)
	if lamp=="vortex_lamp": _arc(player.position+Vector3.UP*0.3,facing,5,color)
	if lamp=="ember_lamp": _burst(player.position+Vector3.UP,color,8,2.5)
	for enemy in enemies:
		if enemy["node"].position.distance_to(player.position)>5: continue
		if lamp=="frost_lamp": enemy["slow"]=maxf(enemy["slow"],2)
		elif lamp=="ember_lamp":
			enemy["burn"]=maxf(enemy.get("burn",0),2)
			enemy["burn_tick"]=0.5
		elif lamp=="vortex_lamp" and enemy["kind"]!="boss": enemy["node"].position=enemy["node"].position.move_toward(player.position,1.1)


func _show_stage_result() -> void:
	state="transition"
	if stage_depth==5:
		ui.show_modal("主线收卷 · "+ChapterFive.ENDINGS[ending_choice][0],"本次故事结局已写定。\n归家：带回全部本次香火，结束此行。\n回响：保留当前成长，挑战更强的卷外愿影，不改写结局。",[{"id":"continue_stage","label":"前往城隍夜簿","detail":"保留状态，进入卷外第六章"},{"id":"cash_out","label":"收卷归家","detail":"带回全部本次香火"}],"终章结算")
		return
	ui.show_modal("墨境已破 · 去留由你","继续：保留血量、装备、技能与成长，下一境更强。\n归家：带回全部本次香火，结束此行并清空局内成长。",[{"id":"continue_stage","label":"继续闯关","detail":"保持当前状态进入下一境"},{"id":"cash_out","label":"见好就收 · 回家","detail":"带回全部本次香火"}],"通关抉择")


func _update_root_mark() -> void:
	if not is_instance_valid(player): return
	if not is_instance_valid(root_mark) or root_mark.get_parent()!=player:
		root_mark=Label3D.new()
		root_mark.name="RootMark"
		root_mark.text="定"
		root_mark.font=load("res://assets/NotoSansSC.ttf")
		root_mark.font_size=72
		root_mark.pixel_size=0.009
		root_mark.outline_size=12
		root_mark.modulate=Color("ffcc73")
		root_mark.outline_modulate=Color("7c2921")
		root_mark.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		root_mark.no_depth_test=true
		root_mark.position=Vector3(0,2.8,0)
		player.add_child(root_mark)
	root_mark.visible=rooted_left>0

func _chapter_pages(ending: bool) -> Array:
	if stage_depth>6:
		return [{"title":"愿境深处 · 第%d境"%stage_depth,"text":"又一重愿契在灯前散开。带着走过的路，继续向前。" if ending else "灯照向尚未醒来的愿境。旧愿重聚，来敌更强；保住这一程修为，击破镇守此境的愿影。"}]
	if chapter==6: return ChapterSix.pages(ending,ending_choice,restored_names)
	if chapter==5: return ChapterFive.pages(ending,ending_choice)
	if chapter==4: return ChapterFour.pages(ending,anchored_lights)
	if chapter==3: return ChapterThree.pages(ending,remembered,released_memories)
	if chapter==1:
		if not ending:
			return [
				{"title":"卷一 · 雾隐渡　｜　有舟不渡","text":"师父陆照川带着宝莲灯灯芯离家，只留下一句：若我迟迟不归，沿灯签来寻。\n\n你追到雾隐渡。江水仍流，渡船却被层层绳结系在岸边。雾里有人反复喊着一个孩子的乳名。"},
				{"title":"镇渡使 · 缚舟","text":"船夫说：再等一趟，她就回来了。\n他曾在洪水里救下满船的人，如今却不许任何人离岸。你须斩开渡口的锁，才能循师父的踪迹去往上游。\n行路：自由探索、杀怪升级；本境升六级或经过六分钟，缚舟现身。灯签藏着他不肯说完的往事。"}]
		return [
			{"title":"卷一终 · 最后一趟船","text":"锁绳断了。缚舟仍攥着那截空绳，问：若我走了，她回来时，谁来接？\n你将渡灯留在岸边：灯可以等她。其他人该过河了。\n他许久没有答话，终于把船推入水中。渡口第一次响起了离岸的桨声。"},
			{"title":"灯签续页 · 听愿祠","text":"船篷里压着师父的旧笺：我答应过替他照见女儿，却只让他学会了等。去听愿祠，别再替我许诺。\n雾散时，你看见船头系着一枚祠中的愿签。留住渡口的愿，来自上游。\n你可以带香火归家，也可以保留此刻的状态，继续寻找陆照川。"}]
	if not ending:
		return [
			{"title":"卷二 · 听愿祠　｜　有愿无归","text":"祠前香烟不散，求愿者一遍遍叩首。有人求亲人归来，有人求一夜无梦。每个人都说自己已得庇佑，却没有一个人记得归家的路。\n百愿娘娘的声音从殿中传来：留在福报里，就不必再失望。"},
			{"title":"百愿娘娘 · 慈悲成契","text":"师父的莲纹没入愿簿。寻找残页，唤醒尚能回应的求愿者，再击败百愿娘娘，解开此地愿契。\n金圈先回血；连续停留两秒会定身，头顶显「定」。提前离圈，或按踏影解缚。转红的金圈即将炸裂。\n本境升六级或经过六分钟，首领现身。"}]
	var release: String="你曾唤醒的 %d 位求愿者，最先直起身子。"%rescued if rescued>0 else "愿契碎裂后，最前排的求愿者终于直起身子。"
	return [
		{"title":"卷二终 · 还愿于人","text":"百愿娘娘问：他们来求我不再痛苦。我成全了，何错之有？\n你翻开愿簿，让被抹去的最后一行重见灯光：他们也该能说，不愿。\n朱砂一行行褪去。%s 有人哭，有人仍坐着，有人朝山门走去。这一次，无人替他们决定。"%release},
		{"title":"陆照川手札 · 灯中之命","text":"殿后的灯座刻着师父的名字。他并非误入此地，而是亲手续过这盏留人的灯。\n手札末页写着：那孩子的命系在灯中。我以为留住一条命，就能偿还从前。可这些被我留下的人，又该由谁偿还？\n页缝夹着一张写有「忘川」的引路签。寻找师父，已不只是把他带回家。"}]

func _play_chapter_book(ending: bool) -> void:
	if ending and stage_depth==5 and ending_choice.is_empty():
		_show_final_choice()
		return
	if test_mode or capture_mode:
		if ending: _show_stage_result()
		return
	state="chronicle"
	ui.hide_modal()
	ui.set_combat_visible(false)
	ui.move_vector=Vector2.ZERO
	ui.attack_held=false
	var book=load("res://scripts/chapter_book.gd").new()
	add_child(book)
	book.finished.connect(func():
		if ending: _show_stage_result()
		else:
			state="playing"
			ui.set_combat_visible(true)
	)
	book.open(chapter,_chapter_pages(ending),ui._root.theme)


func _begin_last_words(force: bool=false) -> void:
	if (test_mode or capture_mode) and not force:
		_play_chapter_book(true)
		return
	state="last_words"
	ui.set_combat_visible(false)
	last_words_index=0
	_show_last_words_line()

func _show_last_words_line() -> void:
	var lines: Array=ChapterSix.dialogue() if stage_depth==6 else ChapterFive.dialogue() if stage_depth==5 else (ChapterFour.dialogue() if stage_depth==4 else ChapterThree.last_words(chapter if stage_depth<=3 else 4))
	if last_words_index>=lines.size():
		ui._modal_description.visible_characters=-1
		_play_chapter_book(true)
		return
	var line: Array=lines[last_words_index]
	ui.show_modal(line[0],line[1],[{"id":"words_next","label":"听下去" if last_words_index<lines.size()-1 else "收好这段话"},{"id":"words_skip","label":"略过对话"}],("灯前问答 · %d / %d" if stage_depth==5 else ("真君收刀 · %d / %d" if stage_depth==4 else "首领临终 · %d / %d"))%[last_words_index+1,lines.size()])
	ui._modal_description.visible_characters=0
	words_tween=create_tween()
	words_tween.tween_property(ui._modal_description,"visible_characters",str(line[1]).length(),maxf(1.0,str(line[1]).length()*0.055))

func _next_last_words() -> void:
	if ui._modal_description.visible_characters>=0 and ui._modal_description.visible_characters<ui._modal_description.text.length():
		if words_tween: words_tween.kill()
		ui._modal_description.visible_characters=-1
		return
	if words_tween: words_tween.kill()
	last_words_index+=1
	_show_last_words_line()

func _hear_final_voice(key: int, after_battle: bool) -> void:
	if key not in final_voices: final_voices.append(key)
	var voice: Array=ChapterFive.VOICES[key]
	state="ending_voice" if after_battle else "story"
	ui.show_modal(voice[0],voice[1],[{"id":"ending_return" if after_battle else "begin","label":"记下这份心愿"}],"留门线索 · %d / 3"%final_voices.size())

func _show_final_choice() -> void:
	state="ending_choice"
	ui.move_vector=Vector2.ZERO
	ui.attack_held=false
	ui.set_combat_visible(false)
	var cards: Array=[
		{"id":"ending_keep","label":"续灯","detail":"保住眼前的愿境，承担继续借命的代价"},
		{"id":"ending_break","label":"破灯","detail":"停止借命，愿境与自己的借形一同散去"},
		{"id":"ending_open","label":"留门" if final_voices.size()==3 else "留门 · 心愿 %d / 3"%final_voices.size(),"detail":"停止借命，归还名字，让去留由每个人决定","disabled":final_voices.size()<3}]
	if final_voices.size()<3: cards.append({"id":"ending_listen","label":"听灯中人说完","detail":"补听尚未听过的心愿，再作决定"})
	ui.show_modal("灯为谁明","三圣母：看清每条路的代价，再给出你的回答。\n这次选择决定本次故事结局。收卷后仍可归家，或挑战卷外余烬回响。",cards,"终章抉择")


func _clear_combat_buffer() -> void:
	queued_skill=-1
	skill_buffer=0
	dash_buffer=0
	attack_buffer=0

func _request_skill(slot: int) -> void:
	if state!="playing" or slot<0 or slot>=3: return
	if skill_cds[slot]>0.16: return
	if dash_left>0 or skill_cds[slot]>0:
		queued_skill=slot
		skill_buffer=0.22
	else:
		queued_skill=-1
		skill_buffer=0
		_cast_skill(slot)

func _request_dash(direction: Vector3) -> void:
	if state!="playing" or dash_cd>0.14: return
	if dash_cd>0:
		dash_buffer=0.20
		buffered_dash_direction=direction
	else:
		dash_buffer=0
		_dash(direction)

func _tick_combat_buffer(dt: float) -> void:
	dash_buffer=maxf(0,dash_buffer-dt)
	skill_buffer=maxf(0,skill_buffer-dt)
	if dash_buffer>0 and dash_cd<=0:
		dash_buffer=0
		_dash(buffered_dash_direction)
	if skill_buffer>0 and queued_skill>=0 and dash_left<=0 and skill_cds[queued_skill]<=0:
		var slot: int=queued_skill
		queued_skill=-1
		skill_buffer=0
		_cast_skill(slot)
	if skill_buffer<=0: queued_skill=-1

func _cancel_weapon_pose() -> void:
	hit_stop=0
	attack_pose=0
	if weapon_tween and weapon_tween.is_valid(): weapon_tween.kill()
	var socket: Node3D=player.find_child("Weapon",true,false)
	if socket:
		socket.position=Vector3.ZERO
		socket.rotation=Vector3.ZERO

func _strike_impact(pos: Vector3, color: Color, finisher: bool) -> void:
	if effects.get_child_count()>150: return
	var side: Vector3=Vector3(-facing.z,0,facing.x)
	var size: float=0.60 if finisher else 0.36
	_bolt(pos-side*size-Vector3.UP*size,pos+side*size+Vector3.UP*size,color)
	if finisher:
		_bolt(pos+side*size-Vector3.UP*size,pos-side*size+Vector3.UP*size,Color("fff0c9"))
