extends SceneTree
var failures: Array[String]=[]
func _initialize(): call_deferred("run")
func check(value: bool, reason: String):
 if not value: failures.append(reason)
func prepare(g: Node, boss: Dictionary, pattern: int):
 g.state="playing"
 g.hp=500
 g.max_hp=500
 g.shield_hp=0
 g.immunity=0
 g.rooted_left=0
 g.root_ward=0
 g.player.position=Vector3.ZERO
 boss["node"].position=Vector3(0,0,5)
 boss["count"]=pattern-1 if pattern>0 else 2
 g._telegraph(boss)
func run():
 var g=load("res://main.tscn").instantiate()
 root.add_child(g)
 g.set_process(false)
 g.test_mode=true
 g.music_player.stop()
 g._start_run()
 g._on_action("begin")
 g._start_expedition()
 g.level=32
 g.xp=123
 g.wave_number=82
 for i in range(5):
  g._finish_run(true)
  if g.stage_depth==5: g._on_action("ending_break")
  g._advance_stage()
 check(g.stage_depth==6 and g.chapter==6 and g.ending_choice=="break","route and ending preserved")
 check(g.level==32 and g.xp==123 and g.wave_number==82,"growth retained")
 check(g._chapter_name()=="城隍夜簿" and g.world.landmarks.size()==7,"new city map")
 for choice in ["keep","break","open"]:
  g.ending_choice=choice
  check(g._chapter_pages(false)[0]["text"].contains(g.ChapterSix.BRANCHES[choice]),"opening respects each ending")
  check(g._chapter_pages(true)[1]["text"].contains(g.ChapterSix.BRANCHES[choice]),"closing respects each ending")
 g.ending_choice="break"
 for pickup in g.pickups:
  if pickup["kind"]=="restore_name":
   g.player.position=pickup["pos"]
   g._interact()
   g._on_action("begin")
   g._interact()
   g._on_action("begin")
 check(g.restored_names==2 and g.shield_hp==30,"name restoration once per pickup")
 for pickup in g.pickups:
  if pickup["kind"]=="story":
   g.player.position=pickup["pos"]
   g._interact()
   check(g.ui._modal_description.text==g.ChapterSix.FRAGMENTS[pickup["id"]],"city fragments")
   g._on_action("begin")
 var boss: Dictionary=g._spawn_enemy("boss",Vector3(0,0,5))
 check(boss["node"].get_meta("original_model")=="boss_debt","original debt boss model")
 prepare(g,boss,0)
 g._resolve_enemy_attack(boss)
 check(g.hp<500 and g.rooted_left>0 and g.root_mark.visible,"stamp damage and overhead root")
 g.dash_cd=0
 g._dash(Vector3.RIGHT)
 check(g.rooted_left==0,"dash cleanses stamp")
 prepare(g,boss,0)
 g.immunity=1
 g._resolve_enemy_attack(boss)
 check(g.hp==500 and g.rooted_left==0,"invulnerability prevents root")
 prepare(g,boss,0)
 g.player.position=Vector3(0,0,4)
 g._resolve_enemy_attack(boss)
 check(g.hp==500,"stamp evasion")
 for side in [0.0,2.0]:
  prepare(g,boss,1)
  g.player.position=Vector3(side,0,0)
  g._resolve_enemy_attack(boss)
  check((g.hp<500)==(side==0),"chain hit and sidestep")
 prepare(g,boss,1)
 g.player.position=Vector3(0,0,8)
 g._resolve_enemy_attack(boss)
 check(g.hp==500,"chain ends match warning")
 prepare(g,boss,2)
 g._resolve_enemy_attack(boss)
 check(g.hp==500,"pair center gap safe")
 prepare(g,boss,2)
 g.player.position=boss["debt_points"][0]
 g._resolve_enemy_attack(boss)
 check(g.hp<500,"pair circle hit")
 for i in range(8):
  prepare(g,boss,2)
  g.player.position=Vector3(cos(i*TAU/8),0,sin(i*TAU/8))*53.9
  boss["count"]=1
  g._telegraph(boss)
  check(boss["debt_points"][0].distance_to(boss["debt_points"][1])>6.2,"edge pair separation")
 prepare(g,boss,1)
 var marks: Array=boss["debt_marks"].duplicate()
 g._damage_enemy(boss,100000000,g.player.position)
 await process_frame
 for mark in marks: check(not is_instance_valid(mark),"death clears marks")
 check(g.state=="transition","victory settles once")
 g._begin_last_words(true)
 check(g.ui._modal_title.text=="百契债身","debt final dialogue")
 g._on_action("words_skip")
 g.test_mode=false
 g._play_chapter_book(true)
 var book=g.get_child(g.get_child_count()-1)
 check(book.pages[0]["text"].contains("2 份错契"),"book remembers names")
 book.close()
 g.test_mode=true
 if DisplayServer.get_name()!="headless":
  g.ui.hide_modal()
  g.state="playing"
  g.player.position=g.world.landmarks[6]["pos"]+Vector3(0,0,6)
  g.camera.position=g.player.position+Vector3(0,22,18)
  g.camera.look_at(g.player.position)
  boss=g._spawn_enemy("boss",g.player.position+Vector3(0,0,-4))
  boss["count"]=1
  g._telegraph(boss)
  g.ui.set_combat_visible(true)
  g._update_hud()
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/城隍夜簿预览.png")
  g._begin_last_words(true)
  g._next_last_words()
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/夜簿对话预览.png")
  g._on_action("words_skip")
 g._advance_stage()
 check(g.stage_depth==7 and g.chapter==6 and g.ending_choice=="break","later echo keeps branch")
 g._finish_run(true)
 g._cash_out()
 check(not g.journey_started and g.ending_choice.is_empty() and g.restored_names==0,"home clears run evidence")
 if failures.is_empty(): print("CHAPTER13_PASS: route, three branches, names, fragments, stamp/root/dash, chain, pair, edge separation, cleanup, dialogue, book, cashout")
 else: print("CHAPTER13_FAIL: ",failures)
 quit(0 if failures.is_empty() else 1)
