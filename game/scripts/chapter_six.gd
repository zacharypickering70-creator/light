extends RefCounted
const NAMES=["夜簿城门","归名坊","照账亭","无主巷","还契庭","公议碑","城隍案前"]
const FRAGMENTS={3:"夜簿残页：张家求父亲归来，借命却记在李家孩子名下。愿是真的，签名是假的；核账者抄了三遍，错名也便成了旧例。",5:"城隍示谕：欠下的须偿，冒认的须辨。不得以姓名相同便认作一人，不得以恩情抵去旁人的损失。账要对人，不能让人一辈子对着账。"}
const BRANCHES={
"keep":"你选择续灯。灯还亮着，借来的夜也仍在累积。城隍差使把新账放到你面前：先从你自己的签名查起。",
"break":"你选择破灯。此身已经随愿境散去，夜簿里留下的却还有你替人照路的回响。这一卷记的是散灯之后的人间，不是让那一场告别重来。",
"open":"你选择留门。人们开始归家，旧账却没有随门打开而消失。差使请你核对归人的名字：放人走是开始，还要让他们不背着别人的债生活。"}
static func pages(ending: bool, choice: String, names: int) -> Array:
	if not ending:
		return [{"title":"卷外六 · 城隍夜簿","text":BRANCHES.get(choice,BRANCHES["open"])+"\n城门下有人抱着一张不属于自己的欠契。他已经解释了半生，纸上的字却总比他的话响。"},{"title":"百契债身 · 账应当对人","text":"自由探索照账亭、还契庭，核对两份被冒认的愿契；无主巷和公议碑有旧账线索。\n本境升六级或六分钟后债身现形。避开落印的朱圈，链线锁定后向两侧走，双印落下前离圈。落印命中会短暂定身，可用踏影解缚。"}]
	return [{"title":"卷六终 · 名字不是罪","text":"你辨明了 %d 份错契。百契债身散成纸页，仍有人伸手去捡：没有这张债，我该怎么证明自己受过苦？\n差使没有烧掉夜簿。他把损失留下，把冒认的名字划去。承认受过的伤，不必再找一个无辜的人承受。"%names},{"title":"账外余灯","text":BRANCHES.get(choice,BRANCHES["open"])+"\n今夜的账已核清一页，还有更多声音等着被听见。可以携香火归家，也可继续挑战余烬回响；你的第五章选择仍然保留在这一卷的来路中。"}]
static func dialogue() -> Array:
	return [["百契债身","纸上有名，便该有人偿。若无人偿，那些失去算什么？"],["提灯回响","失去是真的。可写错的名字，不会因此变对。"],["城隍差使","留证，辨名，追责。城隍簿记的是人间，不是拿人填满一册账。"],["百契债身","原来记住一场苦，不必再造一场苦……"]]
static func telegraph(g: Node, enemy: Dictionary) -> void:
	clear_marks(enemy)
	var pattern: int=int(enemy["count"])%3
	enemy["attack"]=["debt_stamp","debt_chain","debt_pair"][pattern]
	enemy["target"]=g.player.position
	enemy["target"].y=0
	enemy["timer"]=1.6 if enemy["hp"]>enemy["max_hp"]*0.5 else 1.35
	enemy["attack_radius"]=3.1
	enemy["tell"]=null
	var center: Vector3=enemy["target"]
	center=center.limit_length(g.world.map_radius-8)
	enemy["debt_center"]=center
	if pattern==1:
		var direction: Vector3=g.player.position-enemy["node"].position
		direction.y=0
		if direction.length_squared()<0.01: direction=Vector3.FORWARD
		direction=direction.normalized()
		enemy["debt_direction"]=direction
		var strip:=MeshInstance3D.new()
		var shape:=BoxMesh.new()
		shape.size=Vector3(2.4,0.025,14)
		strip.mesh=shape
		strip.material_override=g._material(Color(0.8,0.2,0.12,0.5))
		g.effects.add_child(strip)
		strip.position=center+Vector3.UP*0.065
		strip.rotation.y=atan2(direction.x,direction.z)
		enemy["debt_marks"].append(strip)
		g.ui.toast("追契锁 · 向链线两侧闪避")
	else:
		enemy["debt_points"]=[center] if pattern==0 else [center+Vector3(-3.6,0,0),center+Vector3(3.6,0,0)]
		for pos in enemy["debt_points"]: enemy["debt_marks"].append(g._disc(pos,3.1,Color(0.82,0.17,0.1,0.4)))
		g.ui.toast("落印 · 离开朱圈，命中可踏影解缚" if pattern==0 else "两契并罚 · 离开双印")
static func clear_marks(enemy: Dictionary) -> void:
	for mark in enemy.get("debt_marks",[]):
		if is_instance_valid(mark): mark.queue_free()
	enemy["debt_marks"]=[]
static func resolve(g: Node, enemy: Dictionary) -> void:
	clear_marks(enemy)
	var hit: bool=false
	if enemy["attack"]=="debt_chain":
		var offset: Vector3=g.player.position-enemy["debt_center"]
		var along: float=offset.dot(enemy["debt_direction"])
		var side: float=offset.cross(enemy["debt_direction"]).length()
		hit=absf(along)<7 and side<1.2
		for i in range(7): g._burst(enemy["debt_center"]+enemy["debt_direction"]*(i-3)*2+Vector3.UP*.3,Color("c5ad73"),3,0.7)
	else:
		for pos in enemy["debt_points"]:
			if g.player.position.distance_to(pos)<3.1: hit=true
			g._ring(pos,3.1,Color("cda876"),0.5)
	if hit:
		var vulnerable: bool=g.immunity<=0
		g._hurt_player(34.0*float(enemy.get("power",1.0))*(0.75 if enemy.get("weak",0.0)>0 else 1.0))
		if vulnerable and g.state=="playing" and enemy["attack"]=="debt_stamp" and g.root_ward<=0:
			g.rooted_left=maxf(g.rooted_left,0.7)
			g._update_root_mark()
	if g.state!="playing": return
	enemy["mode"]="recover"
	enemy["timer"]=1.8
