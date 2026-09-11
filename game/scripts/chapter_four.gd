extends RefCounted

const NAMES=["华山山门","松风坪","照影亭","问心石","回灯崖","旧誓碑","天眼台"]
const FRAGMENTS={
3:"守界录：真君封住的不是山路，而是愿境向山下漫出的裂口。每多亮一盏借命的灯，界石便向人间退一寸。天眼能照见裂口，却不能替灯中人决定去留。",
5:"陆照川旧誓：我已寻得断契之法。若临事又怯，求真君替从前的我，将他们送出来。\n背面另有新墨：最后一盏若是他的，我还是做不到。"}

static func pages(ending: bool, anchors: int) -> Array:
	if not ending:
		return [
			{"title":"卷四 · 华山照影　｜　天眼无私","text":"陆判的信遇到山风，纸上旧墨一字字亮起。信不是求二郎神救你，而是求他在陆照川反悔时，替他守住曾经的决定。\n你抬头看山。云里挂着成千盏灯，山下却有村落一户户暗下去。\n原来师父留住的每一夜，都有人在别处等天亮。"},
			{"title":"二郎显圣真君 · 先看清，再出手","text":"二郎神守在愿境裂口前：你若只想把师父带回去，今日便止步。先证明，你看得见灯外的人。\n自由探索华山，照影亭和回灯崖可稳住归灯，问心石与旧誓碑留有真相。杀怪成长，本境升六级或经过六分钟，真君现身。\n天眼会把真假落点标成「实」「虚」；避开实圈。封界时，青色内圈只对这一招安全，也可退到外圈之外。"}]
	return [
		{"title":"卷四终 · 替从前的我","text":"三尖两刃刀收回身侧，天眼仍亮着。二郎神递来旧誓的原件：你师父曾走到这里，也曾决定结束愿境。\n直到他看见最后熄灭的那盏灯，是你。\n他没有被谁夺走心智。他只是把本该承担的失去，一次次推给别人。"},
		{"title":"灯外之人","text":"这一程，你稳住了 %d 处归灯。裂口那边，断续传来人的呼吸。\n你终于明白，师父救过你，是真的；他的灯困住别人，也是真的。看清后者，不必抹掉前者，却不能再以恩情替伤害作答。\n二郎神说：天眼可以照破幻相，替不了你在看清之后迈出的那一步。"%anchors},
		{"title":"前往莲心台","text":"真君为你留下一道界隙，只容一盏灯通过。他要守住山下，不能替你走进师父最后的愿。\n你将旧信贴近灯芯：这次，我会听他说完。也会让他听见，灯外的人在说什么。\n远处莲心台的灯海依旧明亮。此刻可以带香火归家，也可穿过界隙，前往莲心台面对师父。"}]

static func dialogue() -> Array:
	return [
		["二郎神","收刀。你已看见实影，为什么最后一击还留了余地？"],
		["提灯人","我来问路，不是来让每个挡路的人消失。"],
		["二郎神","陆照川当年，也这样说。他后来怕的，不是看不清，是看清之后仍要失去。"],
		["提灯人","所以他请你，在他反悔时，替他把人送出来。"],
		["二郎神","是。你不欠这盏灯一条命。可灯外的人，也不欠你们一个永不天明的夜。去莲心台，亲口问他。"]]

static func clear_marks(enemy: Dictionary) -> void:
	for mark in enemy.get("sky_marks",[]):
		if is_instance_valid(mark): mark.queue_free()
	enemy["sky_marks"]=[]

static func telegraph(g: Node, enemy: Dictionary) -> void:
	clear_marks(enemy)
	var pattern: int=int(enemy["count"])%3
	enemy["attack"]=["sky_eye","sky_spear","sky_ring"][pattern]
	enemy["target"]=g.player.position if pattern!=2 else enemy["node"].position
	enemy["target"].y=0
	enemy["aim"]=g.player.position
	enemy["timer"]=1.8 if enemy["hp"]>enemy["max_hp"]*0.5 else 1.5
	enemy["sky_duration"]=enemy["timer"]
	enemy["attack_radius"]=2.2 if pattern==0 else (3.0 if pattern==1 else 7.0)
	enemy["tell"]=null
	if pattern==0:
		enemy["sky_revealed"]=false
		enemy["sky_true"]=g.rng.randi_range(0,2)
		enemy["sky_points"]=[]
		var center: Vector3=enemy["target"]
		center=center.limit_length(maxf(0.0,g.world.map_radius-8.0))
		for i in range(3):
			var pos: Vector3=center+Vector3((i-1)*5.5,0,0)
			enemy["sky_points"].append(pos)
			enemy["sky_marks"].append(g._disc(pos,2.2,Color(0.83,0.7,0.36,0.32)))
		g.ui.toast("天眼照影 · 等实虚显形，避开实圈")
	else:
		enemy["tell"]=g._disc(enemy["target"],enemy["attack_radius"],Color(0.85,0.17,0.11,0.28))
		if pattern==2:
			enemy["sky_marks"].append(g._disc(enemy["target"],2.6,Color(0.15,0.75,0.62,0.65)))
			g.ui.toast("封界 · 此招可贴近青圈躲避，或退至外圈之外")
		else: g.ui.toast("三尖破岳 · 落点已定，离开朱圈")

static func tick_reveal(g: Node, enemy: Dictionary) -> void:
	if enemy.get("attack","")!="sky_eye" or enemy.get("sky_revealed",true): return
	if enemy["timer"]>enemy["sky_duration"]-0.55: return
	enemy["sky_revealed"]=true
	for i in range(3):
		var real: bool=i==enemy["sky_true"]
		var mark: MeshInstance3D=enemy["sky_marks"][i]
		mark.material_override.albedo_color=Color(0.9,0.18,0.1,0.6) if real else Color(0.45,0.57,0.57,0.14)
		var word:=Label3D.new()
		word.text="实" if real else "虚"
		word.font=g.ui._root.theme.default_font
		word.font_size=64
		word.pixel_size=0.012
		word.modulate=Color("ffe6b1") if real else Color("a7c7c5")
		word.outline_modulate=Color("253d3c")
		word.outline_size=10
		word.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		word.no_depth_test=true
		word.shaded=false
		word.render_priority=2
		word.outline_render_priority=1
		g.effects.add_child(word)
		word.position=enemy["sky_points"][i]+Vector3.UP*0.5
		enemy["sky_marks"].append(word)

static func resolve(g: Node, enemy: Dictionary) -> void:
	clear_marks(enemy)
	var pos: Vector3=enemy["target"]
	var distance: float=g.player.position.distance_to(pos)
	var hit: bool=false
	match enemy["attack"]:
		"sky_eye":
			pos=enemy["sky_points"][enemy["sky_true"]]
			hit=g.player.position.distance_to(pos)<2.55
			g._ring(pos,2.2,Color("e8c778"),0.5)
			g._burst(pos+Vector3.UP,Color("ffe1a4"),18,2)
		"sky_spear":
			enemy["node"].position=pos
			hit=distance<3.35
			g._ring(pos,3,Color("c8d9d3"),0.5)
		"sky_ring":
			hit=distance>2.6 and distance<7.35
			g._ring(pos,7,Color("e7c378"),0.5)
	if hit: g._hurt_player(30.0*float(enemy.get("power",1.0))*(0.75 if enemy.get("weak",0.0)>0 else 1.0))
	if g.state!="playing": return
	enemy["mode"]="recover"
	enemy["timer"]=2.0 if enemy["attack"]=="sky_eye" else 1.35
