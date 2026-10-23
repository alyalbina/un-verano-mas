extends SceneTree
var game:Node
var checks:=0
var failures:=0
var capture:=false
var samples:Array[float]=[]
func _init()->void:call_deferred("run")
func check(ok:bool,name:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("QA: "+name)
func frames(n:int=3)->void:
	for i:int in n:await process_frame
func screen_point(p:Vector2)->Vector2:
	if is_instance_valid(game) and game.modal=="" and p.y>=95 and p.y<=630:return game.get_viewport().get_canvas_transform()*p
	return p
func click(p:Vector2)->void:
	p=screen_point(p)
	if p.x<0 or p.x>1280 or p.y<0 or p.y>720:
		check(false,"Attempt to click outside visible viewport: "+str(p));return
	Input.warp_mouse(p)
	var motion:=InputEventMouseMotion.new();motion.position=p;motion.global_position=p;Input.parse_input_event(motion);await frames(2)
	var e:=InputEventMouseButton.new();e.position=p;e.global_position=p;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=true;Input.parse_input_event(e);await frames(2)
	e=InputEventMouseButton.new();e.position=p;e.global_position=p;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=false;Input.parse_input_event(e);await frames(2)
func key(code:int)->void:
	var e:=InputEventKey.new();e.keycode=code;e.pressed=true;Input.parse_input_event(e);await frames(2)
	e=InputEventKey.new();e.keycode=code;e.pressed=false;Input.parse_input_event(e);await frames(2)
func drag(a:Vector2,b:Vector2)->void:
	a=screen_point(a);b=screen_point(b)
	Input.warp_mouse(a)
	var e:=InputEventMouseButton.new();e.position=a;e.global_position=a;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=true;Input.parse_input_event(e);await frames(2)
	for i:int in range(1,13):
		var p:=a.lerp(b,float(i)/12);Input.warp_mouse(p)
		var m:=InputEventMouseMotion.new();m.position=p;m.global_position=p;m.relative=(b-a)/12;m.button_mask=MOUSE_BUTTON_MASK_LEFT;Input.parse_input_event(m);await frames(2)
	e=InputEventMouseButton.new();e.position=b;e.global_position=b;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=false;Input.parse_input_event(e);await frames(2)
func settle(seconds:float=8)->void:
	var end:=Time.get_ticks_msec()+int(seconds*1000)
	while Time.get_ticks_msec()<end:
		await process_frame
		if not game.transitioning and game.world.path.is_empty() and not game.world.cat_busy:
			if not is_instance_valid(game.world.panorama) or absf(game.world.panorama.camera.position.x-game.world.panorama.target_x())<.3:break
	await frames(3)
func shot(id:String)->void:
	if not capture:return
	Input.warp_mouse(Vector2(1266,711))
	var m:=InputEventMouseMotion.new();m.position=Vector2(1266,711);m.global_position=m.position;Input.parse_input_event(m);await frames(2)
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://tests/capture_reboot_"+id+".png")
func run()->void:
	capture="--capture" in OS.get_cmdline_user_args()
	game=load("res://scenes/reboot.tscn").instantiate();root.add_child(game);await frames(15)
	check(game.chapter.location=="courtyard","Startup");check(game.world.lucia.base_height==282,"Lucia established scale")
	await shot("01_start")
	await click(Vector2(754,514));await settle();check("wall" in game.chapter.notes,"Wall clue via input")
	await click(Vector2(287,458));
	while not game.cutscene.running:await process_frame
	while game.cutscene.elapsed<3.4:await process_frame
	check(game.world.holding,"Unique holding pose is staged");check(game.world.reveal_amount>.8,"Visible moving shadow")
	await shot("02_discovery")
	await key(KEY_ESCAPE);check(paused,"Native pause inside cinematic")
	var clock:float=game.cutscene.elapsed;await frames(12);check(game.cutscene.elapsed==clock,"Cinematic timeline freezes")
	await key(KEY_ESCAPE);check(not paused,"Native cinematic resume")
	await settle(9)
	check(game.chapter.photo and game.chapter.revealed,"Discovery complete");check(not game.chapter.opened,"No automatic portal")
	await click(Vector2(541,354));await settle();check(game.chapter.photo_placed,"Place photo via scene input")
	await drag(Vector2(528,390),Vector2(596,338));check(not game.chapter.aligned,"Cloth obstruction remains")
	await click(Vector2(73,408));await settle();check(game.chapter.location=="kitchen","Actual doorway transition")
	await click(Vector2(938,425));await settle();check(game.chapter.mirror,"Mirror acquired");await shot("03_kitchen")
	await click(Vector2(162,345));await settle();check(game.chapter.location=="courtyard","Backtracking")
	await click(Vector2(95,666));check(game.selected_item=="mirror","Inventory selection")
	await drag(Vector2(740,578),Vector2(351,507));await settle();check(game.world.cat_phase==1,"Autonomous cat reaches chest")
	await drag(Vector2(350,507),Vector2(513,353));await settle();check(game.world.cat_phase==2,"Cat chooses shelf")
	await drag(Vector2(513,353),Vector2(545,250));await settle();check(game.chapter.laundry_clear,"Companion removes real cloth")
	check(game.world.bg.texture==game.art.courtyard_clear,"Changed environment drawn")
	game.selected_item="";await shot("04_shadow")
	# Revisit does not lose the cat's completed action or continuous settings.
	await click(Vector2(73,408));await settle();await click(Vector2(162,345));await settle()
	check(game.chapter.laundry_clear,"Persistent world change after revisit")
	if not game.chapter.aligned:
		var start:=Vector2(543,383)
		var end:=start+Vector2((746-game.chapter.light_x)/2.6,-(320-game.chapter.light_height)/2.3)
		await drag(start,end)
	check(game.chapter.aligned,"Spatial aim with continuous drag")
	await click(Vector2(754,506));await settle();check(not game.chapter.opened,"Correct door but incomplete route blocked")
	await drag(Vector2(584,590),Vector2(591,602));check(game.chapter.bridge_ready(),"Floor shadow bridge via drag")
	await click(Vector2(754,506));await settle(5);check(game.chapter.opened,"Portal opened with consequence")
	await shot("05_door")
	await click(Vector2(754,506));await settle();check(game.chapter.location=="passage","Impossible space entered")
	await shot("06_passage")
	await click(Vector2(1007,455))
	while not game.cutscene.running:await process_frame
	while game.cutscene.elapsed<2.2:await process_frame
	check(game.world.archive_display and game.world.photo_sprite.texture==game.art.archive_photo,"Two shores revealed as actual staged image")
	await settle(6);check(game.chapter.complete and "archive" in game.chapter.notes,"Story revelation earned")
	check(game.modal=="Два берега","Found image remains inspectable after cinematic")
	await shot("07_archive")
	game.ui_action("notebook");check(game.modal!="" and paused,"Notebook pauses world")
	var old_position:Vector2=game.world.lucia.position;await click(Vector2(707,590));await frames(15);check(game.world.lucia.position==old_position,"Modal blocks walking")
	game.close_modal();check(not paused,"Modal close unpauses")
	game.ui_action("hint");check(not game.chapter.hints.has("after"),"Hint optional, no auto solution")
	game._advance_hint("after");check(game.chapter.hints.after==1,"Tier one");game.close_modal()
	# Actual JSON write/recovery uses a dedicated QA pathname.
	game.test_mode=false;game.save_path="user://qa_reboot_play.json"
	check(game._save_game(),"Atomic disk save")
	var truth:Dictionary=game.chapter.serialize();game.chapter=load("res://scripts/reboot_state.gd").new();game._load_game()
	var loaded:Dictionary=game.chapter.serialize()
	var same:=true
	for key:String in truth:
		if key in ["light_x","light_height","board_angle"]:same=same and is_equal_approx(float(loaded[key]),float(truth[key]))
		else:same=same and loaded[key]==truth[key]
	check(same,"Disk roundtrip restores all world flags")
	DirAccess.rename_absolute(game.save_path,game.save_path+".tmp");game.chapter=load("res://scripts/reboot_state.gd").new();game._load_game()
	check(game.chapter.complete and FileAccess.file_exists(game.save_path),"Temporary save recovery")
	var f:=FileAccess.open(game.save_path,FileAccess.WRITE);f.store_string("{invalid");f.close()
	game.chapter=load("res://scripts/reboot_state.gd").new();game._load_game();check(not game.chapter.photo,"Corrupt save never partially applies")
	var dir:=DirAccess.open("user://");var backup_found:=false
	for name:String in dir.get_files():
		if name.begins_with("qa_reboot_play.json.invalid-"):backup_found=true;dir.remove(name)
	check(backup_found,"Corrupt save preserved");dir.remove("qa_reboot_play.json")
	game.test_mode=true;game.chapter.restore(truth);game._mount("courtyard");game.chapter.location="courtyard";await frames(3)
	check(game.world.bg.texture==game.art.courtyard_clear,"Loaded world matches canonical state")
	game.show_restart();await click(Vector2(806,331));check(game.chapter.complete,"Cancel restart preserves progress");game.close_modal()
	game._restart();check(not game.chapter.photo and not game.chapter.opened,"Intentional restart resets coherent truth")
	for i:int in 60:
		var t:=Time.get_ticks_usec();await process_frame;samples.append((Time.get_ticks_usec()-t)/1000.0)
	samples.sort();print("FRAME SAMPLE median_ms=",samples[30]," p95_ms=",samples[57]," software renderer, not Windows performance")
	print("REBOOT PLAYTHROUGH ",checks-failures,"/",checks)
	game._stop_audio();await create_timer(.3).timeout;quit(1 if failures>0 else 0)
