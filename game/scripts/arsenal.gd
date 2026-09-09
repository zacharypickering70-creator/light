extends RefCounted

const WEAPONS = {
	"ferry_blade":{"name":"朴刀","damage":24.0,"interval":0.34,"reach":3.2,"arc":-0.25,"color":"e9b867","desc":"均衡兵器：中等伤害与攻击速度。可搭配任何套路。"},
	"long_sword":{"name":"青锋剑","damage":18.0,"interval":0.23,"reach":3.5,"arc":0.25,"color":"b9dcd2","desc":"轻快兵器：低单击伤害、高攻击速度。可搭配任何套路。"},
	"long_spear":{"name":"红缨枪","damage":30.0,"interval":0.50,"reach":5.2,"arc":0.80,"color":"e38b72","desc":"长柄兵器：攻击距离最长，伤害较高。可搭配任何套路。"},
	"iron_staff":{"name":"盘龙棍","damage":20.0,"interval":0.30,"reach":3.8,"arc":-1.1,"color":"d9c489","desc":"长棍：中等攻速与较宽攻击距离。可搭配任何套路。"},
	"heavy_cleaver":{"name":"开山斧","damage":43.0,"interval":0.64,"reach":3.0,"arc":0.0,"color":"f09b65","desc":"重型兵器：单击伤害最高，攻击较慢。可搭配任何套路。"}
}
const NAMES = {"ferry_blade":"朴刀","long_sword":"青锋剑","long_spear":"红缨枪","iron_staff":"盘龙棍","heavy_cleaver":"开山斧","pilgrim_robe":"行者衣","iron_robe":"镇渡甲","wind_robe":"轻燕衣","broken_lamp":"归元珠","ember_lamp":"赤烬珠","storm_lamp":"引雷珠","frost_lamp":"寒魄珠","vortex_lamp":"回风珠","ward_lamp":"护莲珠","crimson_robe":"赤霄袍","sage_robe":"太清袍","lotus_robe":"归莲衣"}

const ROBES={
 "pilgrim_robe":{"color":"a07851","desc":"均衡衣甲；击败敌人额外回复 1 气血。"},
 "iron_robe":{"color":"a4aca1","desc":"生命 +16、减伤 18%；移动略慢。"},
 "wind_robe":{"color":"90c8ae","desc":"移动速度 7.1，踏影冷却缩短 15%。"},
 "crimson_robe":{"color":"dc6956","desc":"第三次普攻伤害提高 25%，赤色连段光环。"},
 "sage_robe":{"color":"8bb7cf","desc":"技能灯火消耗降低 3，青色符环。"},
 "lotus_robe":{"color":"c6a7d5","desc":"每 12 秒获得至少 15 护盾，紫色莲纹。"}
}
const LAMPS={
 "broken_lamp":{"color":"eac081","icon":"vortex","desc":"技能消耗降低 5；金色环绕光点。"},
 "ember_lamp":{"color":"df6343","icon":"fire","desc":"红莲掌伤害 +30%；施法给近敌附加灼烧。"},
 "storm_lamp":{"color":"b3abd8","icon":"thunder","desc":"奔雷指多传导 2 人；每第三次普攻连雷。"},
 "frost_lamp":{"color":"88d6e6","icon":"frost","desc":"施法给周围敌人附加 2 秒减速。"},
 "vortex_lamp":{"color":"9bd0a0","icon":"vortex","desc":"施法牵引周围普通敌人。"},
 "ward_lamp":{"color":"dfb9cf","icon":"barrier","desc":"每次施法获得 8 护盾，最多积攒 40。"}
}
