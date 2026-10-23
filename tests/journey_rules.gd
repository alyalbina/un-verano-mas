extends "res://tests/episode_rules.gd"
func _init()->void:
	var s=State.new()
	check(not s.can_enter("workshop") and not s.can_enter("harbor"),"New locations cannot bypass earlier puzzles")
	s.photo=true;s.revealed=true;s.photo_placed=true;s.mirror=true;s.laundry_clear=true
	s.move_projection(746,320);s.move_board(.24);s.try_open();s.visit("passage");s.complete=true
	s.jug=true;s.jug_filled=true;s.seen_arch=true;s.seen_reflection=true;s.street_open=true
	check(s.can_enter("workshop"),"Workshop exploration allowed before echo")
	s.spool_moved=true;s.belt_taken=true;s.belt_installed=true;s.back_seen=true;s.belt_tension=1;s.idle_sector=4
	check(not s.try_frame(),"Mechanical repair cannot invent fountain connection")
	s.cup_filled=true;s.heard_motif=true;s.echo_fixed=true;s.connection_found=true;s.workshop_linked=true
	s.belt_tension=2;check(not s.try_frame(),"Overtightened belt stops the axis")
	s.belt_tension=1;s.idle_sector=0;check(not s.try_frame(),"Return loop still prevents release")
	s.idle_sector=4;check(s.try_frame(),"Release succeeds with physical prerequisites")
	s.frame_taken=true;s.frame_placed=true;s.route_anchor="lake";s.route_loop=false;s.aim_route(-.72)
	check(not s.try_route(),"Correct heading cannot compensate for wrong real-world anchor")
	s.route_anchor="courtyard";s.route_loop=true;check(not s.try_route(),"Closed return still traps light")
	s.route_loop=false;s.aim_route(1);check(not s.try_route(),"Nonharbor direction cannot unlock travel")
	s.aim_route(-.72);check(s.try_route(),"Open direction anchored to courtyard unlocks route")
	s.departed=true;s.visit("harbor");s.positions.harbor=[354,590]
	var raw:Dictionary=s.serialize();var restored=State.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(raw))),"Completed journey survives JSON/disk numeric types")
	check(restored.can_enter("harbor") and restored.route_open and restored.frame_fixed,"Travel and repaired frame retained")
	for key:String in ["belt_taken","spool_moved","belt_installed","back_seen","workshop_linked","frame_fixed","frame_taken","frame_placed","route_open","departed"]:
		var bad:Dictionary=raw.duplicate(true);bad[key]=false
		check(not restored.restore(bad),"Reject missing dependency "+key)
		check(restored.serialize()==raw,"Rejected state remains atomic "+key)
	for value:Variant in [-1,8,2.5,NAN,INF,false]:
		var bad:Dictionary=raw.duplicate(true);bad.idle_sector=value
		check(not restored.restore(bad),"Invalid gear setting rejected")
	var old:Dictionary=raw.duplicate(true);old.schema=6;old.location="street";old.visited=["courtyard","passage","street"];old.positions={}
	for key:String in State.WORKSHOP_BOOL:old.erase(key)
	for key:String in ["belt_tension","idle_sector","route_angle","route_anchor","route_loop"]:old.erase(key)
	check(restored.restore(JSON.parse_string(JSON.stringify(old))),"Actual v0.7 schema migrates without new fields")
	check(restored.connection_found and not restored.frame_fixed,"Migration retains prior solution, does not solve new episode")
	print("JOURNEY RULES ",checks-failures,"/",checks);quit(1 if failures else 0)
