extends RefCounted

const ARTS = {
	"cleave":{"name":"断岳刀法","desc":"前方横斩，第三击重击；击败燃烧敌人引爆周围。所有兵器可用。","arc":-0.25,"speed":1.0},
	"flurry":{"name":"流星快打","desc":"攻击间隔缩短 20%，单击伤害降低 15%；第三击发出剑气。所有兵器可用。","arc":0.2,"speed":0.8},
	"thrust":{"name":"长虹贯日","desc":"攻击距离 +35%，窄幅穿刺；对减速敌人增伤 35%。所有兵器可用。","arc":0.8,"speed":1.0},
	"sweep":{"name":"八方扫叶","desc":"360 度横扫，单击伤害降低 15%；第三击击退敌群。所有兵器可用。","arc":-1.1,"speed":1.1}
}
const SKILLS = {
	"fire":{"name":"红莲掌","color":"ee9767","cost":20.0,"cooldown":5.0,"desc":"群攻：周身爆发，附加 3 秒灼烧。20 灯火，冷却 5 秒。"},
	"frost":{"name":"寒江雪","color":"88ccdc","cost":18.0,"cooldown":6.0,"desc":"控制：周身寒气，减速敌人 3 秒。18 灯火，冷却 6 秒。"},
	"thunder":{"name":"奔雷指","color":"c2adef","cost":22.0,"cooldown":5.5,"desc":"连锁：雷击在最多 8 名近敌间传导。22 灯火，冷却 5.5 秒。"},
	"vortex":{"name":"回风引","color":"b7d0a2","cost":18.0,"cooldown":7.0,"desc":"聚怪：拉近普通敌人并造成范围伤害。18 灯火，冷却 7 秒。"},
	"barrier":{"name":"金钟罩","color":"efcf81","cost":20.0,"cooldown":10.0,"desc":"防护：获得护盾并减伤 30%，持续 5 秒。20 灯火，冷却 10 秒。"},
	"haste":{"name":"踏云诀","color":"9be1c3","cost":15.0,"cooldown":9.0,"desc":"增益：移动与攻击速度提高 25%，持续 5 秒。15 灯火，冷却 9 秒。"},
	"poison":{"name":"蚀骨散","color":"aacb71","cost":18.0,"cooldown":6.0,"desc":"减益：范围中毒 5 秒，敌人受到伤害提高 20%。18 灯火，冷却 6 秒。"},
	"heal":{"name":"回春术","color":"90dab0","cost":22.0,"cooldown":12.0,"desc":"治疗：回复 24 点生命；技能每升一级额外回复 6 点。22 灯火，冷却 12 秒。"},
	"weak":{"name":"断脉掌","color":"b89dc8","cost":18.0,"cooldown":7.0,"desc":"虚弱：范围伤害，敌人输出降低 25%，持续 5 秒。18 灯火，冷却 7 秒。"},
	"darts":{"name":"飞花诀","color":"d9bbcf","cost":16.0,"cooldown":4.0,"desc":"远攻：向前方 9 米扇形射出穿透飞花。16 灯火，冷却 4 秒。"},
	"quake":{"name":"撼地功","color":"d2ad7a","cost":22.0,"cooldown":8.0,"desc":"击退：大范围震击并推开普通敌人。22 灯火，冷却 8 秒。"},
	"stun":{"name":"镇山印","color":"e2b18d","cost":22.0,"cooldown":8.0,"desc":"控制：震伤近敌并眩晕 1.4 秒，首领缩短至 0.35 秒。22 灯火，冷却 8 秒。"}
}
const ULTIMATES = {
	"lotus":{"name":"万莲焚天","color":"f4a36b","desc":"满战意释放：大范围高伤与灼烧。"},
	"tempest":{"name":"九霄雷狱","color":"c5b6ed","desc":"满战意释放：雷击传导最多 16 人并短暂眩晕。"},
	"blizzard":{"name":"千里冰封","color":"a5dbe8","desc":"满战意释放：广域寒伤，长时间减速并短暂定身。"},
	"hurricane":{"name":"龙卷残云","color":"b1d6bd","desc":"满战意释放：大范围卷入敌群并施加易伤，适合接群攻。"},
	"sword_rain":{"name":"万剑归宗","color":"d3e3d7","desc":"满战意释放：向前方 14 米扇形降下剑雨，多目标穿透伤害。"},
	"venom":{"name":"碧落黄泉","color":"b6cf77","desc":"满战意释放：广域毒爆，附加 8 秒中毒和虚弱。"},
	"avatar":{"name":"天罡战体","color":"edcba2","desc":"满战意释放：8 秒内普攻增伤 40%、攻速提高 25%。"},
	"void":{"name":"幽冥断生","color":"c1a3d2","desc":"满战意释放：收割低血量普通敌人，对首领造成高伤。"},
	"meteor":{"name":"天火流星","color":"ef9973","desc":"满战意释放：在近处敌群上方落下流星，爆发伤害与灼烧。"},
	"sanctuary":{"name":"不动明王","color":"efda91","desc":"满战意释放：回复 35% 生命，获得护盾并震退周围敌人。"}
}
const EXTRA_BOONS = [
	{"id":"crit","name":"会心一击","desc":"普攻暴击概率 +12%，暴击造成 1.8 倍伤害。"},
	{"id":"frostbite","name":"霜刃","desc":"普攻有 18% 概率附加 2 秒减速，每层提高概率。"},
	{"id":"venom","name":"淬毒","desc":"普攻有 20% 概率附加 4 秒中毒，每层提高概率。"},
	{"id":"expose","name":"破甲","desc":"技能命中附加 3 秒易伤：基础增伤 20%，每层额外 +8%。"},
	{"id":"execute","name":"追魂","desc":"对生命低于 30% 的敌人伤害 +20%。"},
	{"id":"rage","name":"背水","desc":"自身生命低于 40% 时，普攻伤害 +25%。"},
	{"id":"shield","name":"护心","desc":"每隔 12 秒获得 10 点护盾，可叠加强度。"},
	{"id":"refresh","name":"回气","desc":"全部技能冷却缩短 10%。"},
	{"id":"thrift","name":"节用","desc":"每层减少技能消耗 2 点灯火，最低消耗 5 点。"},
	{"id":"resolve","name":"战意","desc":"命中积攒的绝技战意增加 20%。"},
	{"id":"overload","name":"天威","desc":"绝技伤害或护盾强度 +20%。"},
	{"id":"lotus_step","name":"步步生莲","desc":"每次闪避回复 3 点生命。"},
	{"id":"afterimage","name":"残影","desc":"闪避起点震击附近敌人，造成每层 12 点伤害。"},
	{"id":"thorns","name":"反震","desc":"受到伤害时，对 3 米内敌人反击每层 12 点伤害。"},
	{"id":"hunter","name":"猎首","desc":"对首领与重甲敌人伤害 +15%。"},
	{"id":"long_control","name":"缠丝","desc":"减速、眩晕和易伤持续时间增加 20%。"},
	{"id":"second_wind","name":"息风","desc":"释放技能后回复每层 2 点生命。"},
	{"id":"ash","name":"拾薪","desc":"每次击败敌人额外获得 2 烬砂。"},
	{"id":"soul","name":"悟道","desc":"每次击败敌人额外获得 1 经验。"},
	{"id":"fervor","name":"乘胜","desc":"连斩达到 10 时，普攻伤害 +15%。"}
]

const MINDS = {
	"orbit":{"name":"莲华经","desc":"两枚灯珠环绕攻击。所有兵器和招式通用。"},
	"spark":{"name":"奔雷诀","desc":"每三次普攻命中触发额外连锁雷击。"},
	"leech":{"name":"长生息","desc":"击败敌人回复 2 生命。"},
	"momentum":{"name":"踏风诀","desc":"闪避后两秒普攻伤害 +35%。"},
	"ironwall":{"name":"铁壁功","desc":"受到的伤害降低 15%。"},
	"swift":{"name":"游龙步","desc":"移动速度提高 10%。"},
	"reservoir":{"name":"归元经","desc":"每秒自动回复 2 灯火。"},
	"fury":{"name":"会心诀","desc":"普攻暴击概率 +12%。"},
	"merciful":{"name":"护生经","desc":"击败敌人获得 2 护盾，积攒上限 30。"},
	"focus":{"name":"明镜诀","desc":"三招技能冷却缩短 10%。"}
}
