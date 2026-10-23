extends SceneTree
const State=preload("res://scripts/reboot_state.gd")
var checks:=0
var failures:=0
func check(ok:bool,title:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(title)
func unlocked()->RefCounted:
	var s=State.new();s.photo=true;s.revealed=true;s.photo_placed=true;s.mirror=true;s.laundry_clear=true
	s.move_projection(746,320);s.move_board(.24);s.try_open();s.visit("passage");s.complete=true
	return s
func _init()->void:
	var s=State.new();check(not s.can_enter("street") and not s.can_enter("plaza"),"New episode cannot skip discovery")
	s=unlocked();check(s.can_enter("street") and s.can_enter("plaza"),"Both routes unlock together")
	s.visit("street");check(s.stage()=="water","Location-aware hints")
	check(not s.hold_drain(),"No imaginary jug")
	s.jug=true;check(not s.hold_drain(),"Empty jug cannot hold gate")
	s.jug_filled=true;check(s.hold_drain(),"Filled jug counterweight")
	check(not s.still_water(),"Closed drain alone cannot conjure water")
	s.water_on=true;check(s.still_water(),"Source and closed drain hold water")
	s.turn_mirror(.28);check(s.reflection_angle==-.55,"Unmounted mirror cannot turn")
	s.mirror_mounted=true;s.turn_mirror(.28)
	check(not s.try_reflection(),"Correct angle cannot replace observing evidence")
	s.seen_arch=true;check(not s.try_reflection(),"Second viewpoint required")
	s.seen_reflection=true;s.turn_mirror(-.1);check(not s.try_reflection(),"Wrong angle gives no passage")
	s.turn_mirror(.28);s.water_on=false;check(not s.try_reflection(),"Dry aligned mirror gives no passage")
	s.water_on=true;s.hold_drain();check(not s.try_reflection(),"Flowing aligned reflection gives no passage")
	s.hold_drain();check(s.try_reflection(),"Physical conditions and both views unfold street")
	s.hold_drain();s.water_on=false;s.turn_mirror(-.6);check(s.street_open and is_equal_approx(s.reflection_angle,.28),"Unfolded passage stays anchored")
	s.cup_filled=true;s.valves.assign([false,true,false]);check(not s.try_echo(),"No musical event means no echo")
	s.heard_motif=true
	for i:int in 8:
		s.echo_fixed=false;s.valves.assign([bool(i&1),bool(i&2),bool(i&4)])
		check(s.try_echo()==(i==2),"Only one long route succeeds: "+str(i))
	s.valves.assign([false,true,false]);s.try_echo();s.connection_found=true;s.visit("plaza")
	var raw:Dictionary=s.serialize();var restored=State.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(raw))),"Schema7 JSON roundtrip")
	check(restored.serialize()==raw,"Every episode field persists")
	for key:String in ["jug","jug_filled","seen_arch","seen_reflection","cup_filled","heard_motif","street_open","echo_fixed"]:
		var bad:Dictionary=raw.duplicate(true);bad[key]=false
		check(not restored.restore(bad),"Invalid episode prerequisite rejected: "+key)
		check(restored.serialize()==raw,"Rejected restore stays atomic: "+key)
	for value:Variant in [[false,true], [0,true,false], [false,true,false,true]]:
		var bad:Dictionary=raw.duplicate(true);bad.valves=value;check(not restored.restore(bad),"Invalid valve array rejected")
	for value:float in [NAN,INF,1.1]:
		var bad:Dictionary=raw.duplicate(true);bad.reflection_angle=value;check(not restored.restore(bad),"Invalid mirror angle rejected")
	var recovered:Dictionary=raw.duplicate(true);recovered.mirror_mounted=false
	check(restored.restore(recovered),"Solved street allows recovering the mirror")
	check(restored.street_open and "mirror" in restored.inventory(),"Recovered tool and permanent result coexist")
	var legacy:Dictionary=unlocked()._base_serialize();var migrated=State.new()
	check(migrated.restore(JSON.parse_string(JSON.stringify(legacy))),"v0.5 schema migrates through JSON numeric types")
	check(migrated.complete and not migrated.jug and migrated.valves==[true,false,false],"Migration retains opening and initializes extension")
	check(migrated.serialize().schema==7,"Migrated save writes schema7")
	check(legacy.schema==5 and not legacy.has("jug"),"Migration does not mutate source")
	print("EPISODE RULES ",checks-failures,"/",checks);quit(1 if failures else 0)
