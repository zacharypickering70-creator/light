extends SceneTree
var scene: Node3D
var stage: Node3D
var camera: Camera3D
func _initialize(): call_deferred("run")
func label_at(text: String, pos: Vector3):
 var label:=Label3D.new()
 label.text=text
 label.font=load("res://assets/NotoSansSC.ttf")
 label.font_size=48
 label.pixel_size=0.012
 label.modulate=Color("263b3a")
 label.outline_size=0
 label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 label.no_depth_test=true
 stage.add_child(label)
 label.position=pos
func clear_stage():
 for child in stage.get_children(): child.free()
func capture(file: String):
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/"+file+".png")
func run():
 scene=Node3D.new()
 root.add_child(scene)
 stage=Node3D.new()
 scene.add_child(stage)
 var env:=WorldEnvironment.new()
 env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR
 env.environment.background_color=Color("dfdfcb")
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color=Color("fff7e6")
 env.environment.ambient_light_energy=0.35
 scene.add_child(env)
 var sun:=DirectionalLight3D.new()
 scene.add_child(sun)
 sun.rotation_degrees=Vector3(-50,-30,0)
 sun.light_energy=0.5
 sun.shadow_enabled=true
 var fill:=DirectionalLight3D.new()
 scene.add_child(fill)
 fill.rotation_degrees=Vector3(-20,160,0)
 fill.light_energy=0.15
 var floor_mesh:=MeshInstance3D.new()
 floor_mesh.mesh=PlaneMesh.new()
 floor_mesh.mesh.size=Vector2(60,60)
 var mat:=StandardMaterial3D.new()
 mat.albedo_color=Color("d6d7c2")
 floor_mesh.material_override=mat
 floor_mesh.position.y=-0.02
 scene.add_child(floor_mesh)
 camera=Camera3D.new()
 scene.add_child(camera)
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=14
 camera.position=Vector3(0,9,-17)
 camera.look_at(Vector3(0,1,0))
 camera.current=true
 var library=load("res://scripts/model_library.gd")
 var names=["提灯人","符面刀客","青衣咒师","负甲重卒"]
 for i in range(4):
  var actor: Node3D=library.actor(["player","grunt","ranger","brute"][i])
  stage.add_child(actor)
  actor.position=Vector3((i-1.5)*4.4,0,0)
  actor.scale*=1.6
  actor.rotation.y=-0.28
  label_at(names[i],actor.position+Vector3(0,4.2,0))
 label_at("烬灯行 · 原创角色网格",Vector3(0,5.8,1))
 await capture("原创角色模型预览")
 clear_stage()
 names=["缚舟","百愿娘娘","无名判影","二郎显圣真君","陆照川"]
 camera.size=16
 for i in range(5):
  var actor: Node3D=library.actor("boss",i+1)
  stage.add_child(actor)
  actor.position=Vector3((i-2)*4.5,0,0)
  actor.rotation.y=-0.22
  label_at(names[i],actor.position+Vector3(0,4.9,0))
 label_at("烬灯行 · 五章首领",Vector3(0,6.3,1))
 await capture("原创首领模型预览")
 clear_stage()
 names=["朴刀","青锋剑","红缨枪","盘龙棍","开山斧"]
 camera.size=13
 for i in range(5):
  var weapon: Node3D=library.weapon(["ferry_blade","long_sword","long_spear","iron_staff","heavy_cleaver"][i])
  stage.add_child(weapon)
  weapon.position=Vector3((i-2)*3.5,0.7,1)
  weapon.rotation_degrees=Vector3(0,12,0)
  weapon.scale=Vector3.ONE*1.6
  label_at(names[i],Vector3((i-2)*3.5,0,-2.7))
 label_at("烬灯行 · 五种常用兵器",Vector3(0,4.5,0))
 await capture("原创兵器模型预览")
 print("MODEL_GALLERY_PASS")
 quit()
