extends RefCounted

const NAMES=["入梦门","归人灯市","长明亭","照心池","守门庭","断契碑","莲心台"]
const VOICES={
1:["归人 · 想醒来","我在这里见到了死去的娘，可我的孩子还在山外等我。让我难过吧，也让我回去。"],
2:["留灯人 · 想留下","我知道这是借来的一天。我还没有力气告别。若不再借别人的命，能不能给我一点时间？"],
4:["守门人 · 愿承担","我愿留下照路，但不能替他们许诺。门要开着，账要看得见，想走的人随时可以走。"]}
const FRAGMENTS={
3:"陆照川家书：你小时候练刀，摔了便看我。我总说不疼，再来。后来你真的不再喊疼，我竟以为自己教得很好。原来有些话，我从未让你说出口。",
5:"断契碑：续灯，借命之契仍在；破灯，借形与愿境同散；留门，须停借命、还名字、听去留。守灯者亦须交出替别人许愿的权柄。"}
const ENDINGS={
"keep":["续灯 · 又一夜","你接过灯。师父退到灯照不到的地方。眼前的人仍在，可山下又一扇窗暗了。你把借命的账摊开，第一行就是自己的名字。门外有人问：明日，我能走吗？这一次，回答的人是你。"],
"break":["破灯 · 天将明","你与师父一起折断借命之契。真实的人循晨光归家，画中的一天缓缓散去。师父伸手想扶你，你借灯而成的身形却化成微光。他终于没有再点一盏灯来留下你。天亮了，失去也留在天亮之后。"],
"open":["留门 · 各有归途","三种心愿写在同一扇门上。三圣母的神念解去借命之契，师父将被挤走的名字一一归还。愿境不再向人间取命，只以余火供暂留者告别；没有永不熄灭的保证。你交还反复借形的灯芯，带着会疼、会老的身体走出门。师父留在门边偿还自己的账，不再替任何人决定归期。"]}

static func pages(ending: bool, choice: String) -> Array:
	if not ending:
		return [
			{"title":"卷五 · 莲心台　｜　灯为谁明","text":"二郎神的界隙尽头，是你练刀的旧院。茶还温着，师父说：回来就好，今日不必再出门。\n院外却有人拍门。那声音从雾隐渡、听愿祠、忘川，一直跟到了这里。\n你把旧誓放在桌上：师父，这一次，我们把话说完。"},
			{"title":"陆照川 · 先听见，再作答","text":"探索灯市、长明亭、守门庭，听三个人说出去留；照心池和断契碑记着师父的旧事与断契之法。\n本境升六级或六分钟后迎战师父。落笔朱圈先离开，旧愿环带可退至圈外，最后沿笔锋两侧闪开。预警落下后再反击。\n战后可选择续灯、破灯；听完三种心愿可选择留门，漏听可在战后补听。"}]
	var entry: Array=ENDINGS[choice]
	return [
		{"title":entry[0],"text":entry[1]},
		{"title":"终卷 · 灯外有路","text":"灯曾替人挡住黑夜，也曾替人遮住天明。你走过的路没有让失去变得轻巧，却让每个被留下的人重新有了声音。\n《烬灯行》主线至此收卷。你可以结算香火归家，也可保留这一程的修为挑战余烬回响。后续战斗是卷外回响，不改写刚才的结局。"}]

static func dialogue() -> Array:
	return [
		["陆照川","我只想再听你喊一声师父。后来每一次灯将灭，我都说，再等一晚。"],
		["提灯人","师父。我回来了。可他们也有人在等。"],
		["陆照川","若灯熄了，你会不会也走？"],
		["提灯人","会。我也会怕。可你不能因为怕，就替所有人把门锁上。"],
		["三圣母 · 灯中神念","灯能照路，不能代人走路。续灯须承认所借，破灯须承担所失；若要留门，就先听清门两边的声音。"],
		["陆照川","这回，我把灯交给你。不是要你替我还债，是终于让你自己回答。"]]

static func clear_marks(enemy: Dictionary) -> void:
	for mark in enemy.get("lotus_marks",[]):
		if is_instance_valid(mark): mark.queue_free()
	enemy["lotus_marks"]=[]

static func telegraph(g: Node, enemy: Dictionary) -> void:
	clear_marks(enemy)
	var fraction: float=enemy["hp"]/enemy["max_hp"]
	var phase: int=1 if fraction>0.66 else (2 if fraction>0.33 else 3)
	if phase!=enemy.get("lotus_phase",0):
		enemy["lotus_phase"]=phase
		g.world.show_final_phase(phase,enemy["node"].position)
		g.ui.toast(["落笔成契 · 离开朱圈","旧愿重现 · 退至愿环之外","旧院问心 · 向笔锋两侧闪避"][phase-1])
	enemy["attack"]=["ink_seals","wish_echo","home_stroke"][phase-1]
	enemy["timer"]=[1.65,1.55,1.4][phase-1]
	enemy["target"]=g.player.position
	enemy["target"].y=0
	enemy["tell"]=null
	enemy["attack_radius"]=2.5
	enemy["lotus_points"]=[]
	var center: Vector3=enemy["target"]
	center=center.limit_length(g.world.map_radius-9.0)
	if phase==1:
		for i in range(3):
			var pos: Vector3=center+Vector3((i-1)*5.8,0,0)
			enemy["lotus_points"].append(pos)
			enemy["lotus_marks"].append(g._disc(pos,2.5,Color(0.72,0.12,0.08,0.5)))
	elif phase==2:
		enemy["target"]=enemy["node"].position
		enemy["target"].y=0
		enemy["lotus_marks"].append(g._disc(enemy["target"],7.3,Color(0.83,0.23,0.13,0.38)))
		enemy["lotus_marks"].append(g._disc(enemy["target"],2.8,Color(0.1,0.65,0.58,0.65)))
	else:
		var direction: Vector3=(g.player.position-enemy["node"].position)
		direction.y=0
		if direction.length_squared()<0.01: direction=Vector3.FORWARD
		direction=direction.normalized()
		enemy["stroke_center"]=center
		enemy["stroke_direction"]=direction
		var stroke:=MeshInstance3D.new()
		var shape:=BoxMesh.new()
		shape.size=Vector3(3.6,0.025,12)
		stroke.mesh=shape
		stroke.material_override=g._material(Color(0.85,0.18,0.08,0.45))
		g.effects.add_child(stroke)
		stroke.position=center+Vector3.UP*0.065
		stroke.rotation.y=atan2(direction.x,direction.z)
		enemy["lotus_marks"].append(stroke)
		for side in [-1,1]:
			enemy["lotus_marks"].append(g._disc(center+direction*side*6,1.8,Color(0.85,0.18,0.08,0.45)))
	var word:=Label3D.new()
	word.text=["契","愿","归"][phase-1]
	word.font=g.ui._root.theme.default_font
	word.font_size=64
	word.pixel_size=0.015
	word.modulate=Color("ffe7b5")
	word.outline_modulate=Color("2b2924")
	word.outline_size=12
	word.no_depth_test=true
	word.render_priority=2
	word.outline_render_priority=1
	word.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	g.effects.add_child(word)
	word.position=enemy["node"].position+Vector3.UP*3
	enemy["lotus_marks"].append(word)

static func resolve(g: Node, enemy: Dictionary) -> void:
	clear_marks(enemy)
	var hit: bool=false
	match enemy["attack"]:
		"ink_seals":
			for pos in enemy["lotus_points"]:
				if g.player.position.distance_to(pos)<2.5: hit=true
				g._ring(pos,2.5,Color("c06a43"),0.5)
		"wish_echo":
			var distance: float=g.player.position.distance_to(enemy["target"])
			hit=distance>2.8 and distance<7.3
			g._ring(enemy["target"],7.3,Color("d8ae72"),0.6)
		"home_stroke":
			var offset: Vector3=g.player.position-enemy["stroke_center"]
			var along: float=clampf(offset.dot(enemy["stroke_direction"]),-6,6)
			var nearest: Vector3=enemy["stroke_center"]+enemy["stroke_direction"]*along
			hit=g.player.position.distance_to(nearest)<1.8
			for i in range(7): g._burst(enemy["stroke_center"]+enemy["stroke_direction"]*(i-3)*2.0+Vector3.UP*0.3,Color("ecc887"),3,0.8)
	if hit: g._hurt_player(32.0*float(enemy.get("power",1.0))*(0.75 if enemy.get("weak",0.0)>0 else 1.0))
	if g.state!="playing": return
	enemy["mode"]="recover"
	enemy["timer"]=2.1 if enemy["lotus_phase"]==3 else 1.7
