extends SceneTree
const State=preload("res://scripts/reboot_state.gd")
var checks:=0
var failures:=0
var game:Node
const PATH="user://qa_reboot_startup.json"
func _init()->void:call_deferred("run")
func check(ok:bool,title:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(title)
func frames(n:int=5)->void:
	for i:int in n:await process_frame
func write_state(s:RefCounted)->void:
	var f:=FileAccess.open(PATH,FileAccess.WRITE);f.store_string(JSON.stringify(s.serialize()));f.close()
func start_game()->void:
	game=load("res://scenes/reboot.tscn").instantiate();game.save_path=PATH;root.add_child(game);await frames(15)
func remove_game()->void:
	game._stop_audio();root.remove_child(game);game.queue_free();await create_timer(.3).timeout
func run()->void:
	var s=State.new();s.photo=true;write_state(s);await start_game()
	check(not game.test_mode,"Real startup path")
	check(game.cutscene.running and game.scene_kind=="discover","Interrupted photo scene replayed")
	game.cutscene.speed=3
	while game.cutscene.running:await process_frame
	check(game.chapter.revealed,"Replayed discovery commits")
	await remove_game()
	s.photo=true;s.revealed=true;s.photo_placed=true;s.mirror=true;s.laundry_clear=true;s.move_projection(746,320);s.move_board(.24);s.try_open();s.visit("passage");s.complete=true;write_state(s)
	await start_game();check(game.chapter.location=="passage" and game.chapter.complete,"Complete startup restores actual location")
	check(not game.cutscene.running,"No duplicate completed cinematic")
	game.chapter.visit("courtyard");game._mount("courtyard");await frames();check(game.world.bg.texture==game.art.courtyard_clear,"Saved physical world rebuilt")
	check(game.world.cat.position==Vector2(475,354),"Companion final perch restored")
	game._restart();await frames();check(game.chapter.stage()=="find" and game.chapter.location=="courtyard","Restart stable at startup")
	await remove_game();DirAccess.remove_absolute(PATH);DirAccess.remove_absolute(PATH+".tmp")
	print("REBOOT STARTUP ",checks-failures,"/",checks);quit(1 if failures else 0)
