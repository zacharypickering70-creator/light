extends SceneTree
var failures: Array[String]=[]
func _initialize(): call_deferred("run")
func check(value: bool, reason: String):
 if not value: failures.append(reason)
func run():
 var library=load("res://scripts/model_library.gd")
 var inventory=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/inventory.json"))
 check(inventory.size()==20,"twenty original assets")
 for entry in inventory:
  var packed: PackedScene=load("res://assets/models/"+entry["file"])
  var model=packed.instantiate()
  root.add_child(model)
  var mesh_nodes=model.find_children("*","MeshInstance3D",true,false)
  check(mesh_nodes.size()<=8,"merged part budget: "+entry["file"])
  var faces: int=0
  for mesh in mesh_nodes:
   faces+=mesh.mesh.get_faces().size()/3
   var arrays=mesh.mesh.surface_get_arrays(0)
   check(arrays[Mesh.ARRAY_COLOR].size()>0,"vertex palette present")
  check(faces==entry["triangles"] and faces<2500,"mesh budget and inventory")
  if entry["clips"].size()>0:
   var animation=model.get_node("AnimationPlayer")
   check(animation.has_animation("Walk") and animation.has_animation("Attack") and animation.has_animation("Idle"),"editable animation clips")
  model.free()
 for chapter in range(1,6):
  var model=library.actor("boss",chapter)
  root.add_child(model)
  check(model.get_meta("original_model")==library.BOSSES[chapter-1],"unique chapter boss")
  check(model.scale.is_equal_approx(Vector3(1.68,1.60,1.68)),"boss scale retained")
  check(model.has_node("Body/RightArm/Grip/Weapon"),"hand socket")
  model.free()
 var g=load("res://main.tscn").instantiate()
 root.add_child(g)
 g.set_process(false)
 g.test_mode=true
 g.music_player.stop()
 g._start_run()
 g._on_action("begin")
 for weapon in g.Arsenal.WEAPONS:
  g.progress["equipped"]["blade"]=weapon
  g._refresh_gear_visual()
  var socket=g.player.get_node("Body/RightArm/Grip/Weapon")
  check(socket.get_child_count()==1,"replacement removes old weapon")
  var arm=g.player.get_node("Body/RightArm")
  var before: Vector3=socket.global_position
  arm.rotation.x=-0.7
  check(socket.global_position.distance_to(before)>0.1,"weapon follows hand")
  arm.rotation.x=0
 var cloth=g.player.get_node("Body/Cloth")
 for robe in g.Arsenal.ROBES:
  g.progress["equipped"]["robe"]=robe
  g._refresh_gear_visual()
  check(cloth.material_override.get_shader_parameter("cloth_tint")==Color(g.Arsenal.ROBES[robe]["color"]),"robe palette")
 g._animate_player(0.05,Vector3.RIGHT)
 check(abs(g.player.get_node("Body/LeftLeg").rotation.x)>0.01,"player walk rig")
 g._start_expedition()
 for enemy in g.enemies.duplicate(): enemy["node"].free()
 g.enemies.clear()
 for i in range(65):
  var enemy: Dictionary=g._spawn_enemy("grunt",Vector3((i%9)-4,0,6+float(i/9)))
  library.animate_enemy(enemy["node"],float(i)*0.2,"chase",0)
 check(g.enemies.size()==65,"crowd model population")
 var a=g.enemies[0]["node"].get_node("Body/Cloth")
 var b=g.enemies[1]["node"].get_node("Body/Cloth")
 check(a.mesh==b.mesh and a.material_override==b.material_override,"crowd shares geometry and ink material")
 g._damage_enemy(g.enemies[0],1,g.player.position)
 check(g.enemies[0]["node"].get_node("Body").rotation.x<0,"damage recoil retained")
 g.hp=1
 g.immunity=0
 g.shield_hp=0
 g._hurt_player(10000)
 check(g.state=="dying","new model death starts")
 g._complete_death()
 check(not g.journey_started and g.state=="result","new model returns home")
 if failures.is_empty(): print("MODELS12_PASS: 20 assets, mesh budgets, clips, five bosses, sockets, weapons, robes, motion, 65 shared models, recoil, death")
 else: print("MODELS12_FAIL: ",failures)
 quit(0 if failures.is_empty() else 1)
