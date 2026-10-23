extends "res://tests/reboot_playthrough.gd"
const State=preload("res://scripts/reboot_state.gd")
func unlocked()->RefCounted:
	var s=State.new();s.photo=true;s.revealed=true;s.photo_placed=true;s.mirror=true;s.laundry_clear=true
	s.move_projection(746,320);s.move_board(.24);s.try_open();s.visit("passage");s.complete=true
	return s
func select_inventory(id:String)->void:
	var index:int=game.chapter.inventory().find(id)
	if index<0:check(false,"Missing physical inventory item: "+id);return
	await click(Vector2(45+index*50,668))
func run()->void:
	capture="--capture" in OS.get_cmdline_user_args()
	game=load("res://scenes/reboot.tscn").instantiate();root.add_child(game);await frames(15)
	game.chapter=unlocked();game._mount("passage");await frames(5)
	var deadline:int=0
	await click(Vector2(1135,668));await settle();check(game.chapter.location=="street","Street reached through actual continuation button")
	check(is_instance_valid(game.world.episode),"World mechanism present")
	await shot("08_street")
	await click(Vector2(928,406));await settle();check(not game.chapter.street_open and game.chapter.seen_arch,"Real arch clue, dry door blocked")
	await click(Vector2(325,350));await settle();check(game.chapter.jug,"Jug taken from actual shelf")
	await select_inventory("jug");await click(Vector2(713,413));await settle();check(not game.chapter.drain_held,"Empty counterweight gives visible rejection")
	await click(Vector2(522,343));await settle();check(game.chapter.jug_filled and game.chapter.water_on,"Inventory jug fills at faucet")
	await click(Vector2(526,440));await settle();check(not game.chapter.seen_reflection,"Broken reflection cannot stand in for second view")
	await select_inventory("mirror");await click(Vector2(620,272));await settle();check(game.chapter.mirror_mounted,"Carried mirror mounted on physical hinge")
	await drag(Vector2(621,272),Vector2(725,272));await click(Vector2(928,406));await settle();check(not game.chapter.street_open,"Right geometry with open drain still fails")
	await select_inventory("jug");await click(Vector2(713,413));await settle();check(game.chapter.drain_held and not "jug" in game.chapter.inventory(),"Jug is an actual placed counterweight")
	await click(Vector2(526,440));await settle();check(game.chapter.seen_reflection and game.world.episode.inspection_open,"Second view reveals matching chip and close inspection")
	await shot("09_reflection")
	await key(KEY_N);var before:float=game.chapter.reflection_angle
	await drag(Vector2(621,272),Vector2(581,272));check(game.chapter.reflection_angle==before,"Notebook prevents world drag")
	await key(KEY_ESCAPE)
	await click(Vector2(928,406));await settle(8)
	check(game.chapter.street_open and game.world.bg.texture==game.art.street_open,"Open workshop rendered after causal solution")
	await shot("10_open_street")
	await click(Vector2(713,413));await settle();check(not game.chapter.drain_held and "jug" in game.chapter.inventory(),"Counterweight can always be retrieved")
	check(game.chapter.street_open,"Passage survives reusing its jug")
	await click(Vector2(1196,356));await settle();check(game.chapter.location=="plaza","Square reachable without second puzzle solved")
	await shot("11_plaza")
	await click(Vector2(1110,406))
	deadline=Time.get_ticks_msec()+10000
	while not game.cutscene.running and Time.get_ticks_msec()<deadline:await process_frame
	while game.cutscene.running and game.cutscene.elapsed<1.1:await process_frame
	await key(KEY_ESCAPE)
	var playing_paused:=false
	for player:AudioStreamPlayer in game.audio.players:
		if player.stream!=null and player.stream.resource_path.ends_with("guitar_motif.wav") and player.stream_paused:playing_paused=true
	check(playing_paused,"Actual guitar playback pauses with the musical event")
	await key(KEY_ESCAPE)
	var playing_resumed:=false
	for player:AudioStreamPlayer in game.audio.players:
		if player.playing and not player.stream_paused:playing_resumed=true
	check(playing_resumed,"Guitar playback resumes with its timeline")
	await settle(10);check(game.chapter.heard_motif and not game.chapter.echo_fixed,"Dry music repeat gives causal failure")
	await select_inventory("jug");await click(Vector2(658,307));await settle();check(game.chapter.cup_filled,"Water poured into actual upper cup")
	await click(Vector2(1110,406));await settle(10);check(not game.chapter.echo_fixed,"Short route cannot answer final phrase")
	await click(Vector2(660,438));await settle();check(game.chapter.valves==[true,true,false],"Actual second valve changes connected water path")
	await click(Vector2(1110,406));await settle(10);check(not game.chapter.echo_fixed,"Divided flow destroys distant answer")
	await click(Vector2(490,438));await settle();check(game.chapter.long_route(),"One coherent long route selected through world controls")
	game.ui_action("mute");check(game.chapter.muted,"No audio required")
	await click(Vector2(1110,406))
	deadline=Time.get_ticks_msec()+8000
	while not game.cutscene.running and Time.get_ticks_msec()<deadline:await process_frame
	check(game.cutscene.running,"Music event starts from musician hotspot")
	while game.cutscene.elapsed<1.2:await process_frame
	var old: Array=game.chapter.valves.duplicate();await click(Vector2(490,438));check(game.chapter.valves==old,"Cannot swap hydraulic conditions in the middle of evaluation")
	await key(KEY_ESCAPE);var elapsed:float=game.world.episode.music_elapsed
	await frames(12);check(paused and game.world.episode.music_elapsed==elapsed,"Visible musical sequence freezes on pause")
	await key(KEY_ESCAPE)
	while game.cutscene.running and game.cutscene.elapsed<2.7:await process_frame
	await shot("12_echo")
	deadline=Time.get_ticks_msec()+12000
	while not game.chapter.connection_found and Time.get_ticks_msec()<deadline:await process_frame
	await settle(6)
	check(game.chapter.echo_fixed and game.chapter.connection_found,"Muted route succeeds and joint consequence commits")
	check(game.modal=="Два берега","Combined result remains inspectable")
	await shot("13_connection")
	game.close_modal();await click(Vector2(1129,668));await settle()
	check(game.chapter.location=="street" and game.chapter.street_open and game.chapter.echo_fixed,"Both completed worlds persist through revisit")
	await shot("14_return")
	await click(Vector2(620,272));await settle()
	check(not game.chapter.mirror_mounted and "mirror" in game.chapter.inventory(),"Mounted mirror can be recovered after the passage anchors")
	check(game.chapter.street_open,"Taking the mirror does not erase solved street")
	game.ui_action("hint");check(not game.chapter.hints.has("connection"),"New episode hints stay optional")
	game._advance_hint("connection");check(game.chapter.hints.connection==1,"New hint tier is stored");game.close_modal()
	game.test_mode=false;game.save_path="user://qa_episode_play.json";check(game._save_game(),"Extended state writes atomically")
	var truth:Dictionary=game.chapter.serialize();game.chapter=State.new();game._load_game()
	var loaded:Dictionary=game.chapter.serialize();var equal:=true
	for k:String in truth:
		if k in ["light_x","light_height","board_angle","reflection_angle"]:equal=equal and is_equal_approx(float(loaded[k]),float(truth[k]))
		else:equal=equal and loaded[k]==truth[k]
	check(equal,"All extension and original fields survive actual disk read")
	DirAccess.remove_absolute(game.save_path);game.test_mode=true;game.chapter.restore(truth)
	# A second real-input branch verifies the advertised opposite order.
	game.chapter=unlocked();game._mount("street");await frames(5)
	await click(Vector2(325,350));await settle();await select_inventory("jug");await click(Vector2(522,343));await settle()
	await click(Vector2(1196,356));await settle();await select_inventory("jug");await click(Vector2(658,307));await settle()
	await click(Vector2(490,438));await settle();await click(Vector2(660,438));await settle()
	await click(Vector2(1110,406));await settle(9)
	check(game.chapter.echo_fixed and not game.chapter.street_open and not game.chapter.connection_found,"Square can be solved FIRST without fabricated joint reward")
	await click(Vector2(1129,668));await settle();await select_inventory("mirror");await click(Vector2(620,272));await settle()
	await select_inventory("jug");await click(Vector2(713,413));await settle()
	await drag(Vector2(621,272),Vector2(725,272));await click(Vector2(526,440));await settle();await click(Vector2(928,406));await settle(12)
	deadline=Time.get_ticks_msec()+12000
	while not game.chapter.connection_found and Time.get_ticks_msec()<deadline:await process_frame
	await settle(6)
	check(game.chapter.connection_found,"Reverse order reaches the same complete consequence")
	game.close_modal()
	game._stop_audio();await create_timer(.3).timeout
	print("EPISODE PLAYTHROUGH ",checks-failures,"/",checks);quit(1 if failures else 0)
