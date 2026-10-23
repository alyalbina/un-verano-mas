extends SceneTree
const State=preload("res://scripts/reboot_state.gd")
const PATH="user://qa_episode_startup.json"
const OLD="user://qa_episode_legacy.json"
var game:Node
var checks:=0
var failures:=0
func _init()->void:call_deferred("run")
func check(ok:bool,title:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(title)
func frames(n:int=10)->void:
	for i:int in n:await process_frame
func unlocked()->RefCounted:
	var s=State.new();s.photo=true;s.revealed=true;s.photo_placed=true;s.mirror=true;s.laundry_clear=true
	s.move_projection(746,320);s.move_board(.24);s.try_open();s.visit("passage");s.complete=true;return s
func write_raw(path:String,raw:Dictionary)->void:
	var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(raw));f.close()
func start()->void:
	game=load("res://scenes/reboot.tscn").instantiate();game.save_path=PATH;game.legacy_path=OLD;root.add_child(game);await frames()
func stop()->void:
	game._stop_audio();root.remove_child(game);game.queue_free();await create_timer(.3).timeout
func run()->void:
	DirAccess.remove_absolute(PATH);DirAccess.remove_absolute(PATH+".tmp");DirAccess.remove_absolute(OLD)
	var old:Dictionary=unlocked()._base_serialize();write_raw(OLD,old);var old_bytes:=FileAccess.get_file_as_string(OLD)
	await start();check(not game.test_mode,"Real startup, no --qa")
	check(game.chapter.complete and not game.chapter.jug,"Old save migrates through actual startup")
	check(game._read_json(PATH).schema==7,"New schema saved separately")
	check(FileAccess.get_file_as_string(OLD)==old_bytes,"Old save bytes untouched")
	await stop()
	var s=unlocked();s.jug=true;s.jug_filled=true;s.drain_held=true;s.water_on=true;s.mirror_mounted=true;s.seen_arch=true;s.seen_reflection=true;s.turn_mirror(-.08);s.visit("street")
	write_raw(PATH,s.serialize());await start()
	check(game.chapter.location=="street" and is_instance_valid(game.world.episode),"Actual street rebuilt on startup")
	check(game.chapter.drain_held and not "jug" in game.chapter.inventory(),"Placed counterweight restored")
	check(is_equal_approx(game.chapter.reflection_angle,-.08),"Partial continuous reflection retained")
	check(not game.cutscene.running and not game.chapter.street_open,"Partial experiment does not auto solve")
	await stop()
	s.turn_mirror(.28);s.try_reflection();s.hold_drain();s.cup_filled=true;s.heard_motif=true;s.valves.assign([false,true,false]);s.try_echo();s.visit("plaza")
	write_raw(PATH,s.serialize());await start()
	check(game.chapter.echo_fixed and game.chapter.street_open,"Both solutions retained after interrupted joint reveal")
	check(game.cutscene.running and game.scene_kind=="connection","Joint reveal replays from a safe boundary")
	game.cutscene.speed=3
	while game.cutscene.running:await process_frame
	check(game.chapter.connection_found and game.modal=="Два берега","Replayed joint result commits and displays")
	await stop()
	await start();check(game.chapter.connection_found and not game.cutscene.running,"Completed joint result does not replay twice")
	game.close_modal();game.chapter.visit("street");game._mount("street");await frames()
	check(game.world.bg.texture==game.art.street_open,"Opened scene rebuilt from canonical truth")
	game._restart();await frames();check(not game.chapter.jug and not game.chapter.connection_found and not game.chapter.complete,"Restart resets original and extension coherently")
	await stop();DirAccess.remove_absolute(PATH);DirAccess.remove_absolute(PATH+".tmp");DirAccess.remove_absolute(OLD)
	print("EPISODE STARTUP ",checks-failures,"/",checks);quit(1 if failures else 0)
