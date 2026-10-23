extends SceneTree
const State=preload("res://scripts/reboot_state.gd")
var checks:=0
var failures:=0
func check(ok:bool,name:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(name)
func _init()->void:
	var s=State.new()
	check(s.can_enter("kitchen"),"Kitchen is initially accessible")
	check(not s.can_enter("passage"),"Portal gated")
	s.move_projection(746,320);check(not s.aligned,"Unplaced photo cannot align")
	s.photo=true;s.revealed=true;s.photo_placed=true;s.move_projection(746,320)
	check(not s.aligned,"Towel blocks despite correct geometry")
	s.mirror=true;s.laundry_clear=true;s.move_projection(500,320);check(not s.aligned,"Horizontal mismatch")
	s.move_projection(746,190);check(not s.aligned,"Height mismatch")
	s.move_projection(746,320);check(s.aligned,"Both coordinates match")
	check(not s.try_open(),"Broken floor shadow blocks")
	s.move_board(.24);check(s.bridge_ready(),"Floor connection succeeds")
	check(s.try_open() and s.can_enter("passage"),"Open persists")
	s.visit("passage");check(s.entered,"Visit records narrative")
	s.complete=true
	var saved:Dictionary=s.serialize();var restored=State.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(saved))),"JSON roundtrip")
	check(restored.serialize()==saved,"Roundtrip exact truth")
	for key:String in ["photo","revealed","mirror","photo_placed","laundry_clear","aligned","opened","entered"]:
		var bad:Dictionary=saved.duplicate(true);bad[key]=false
		check(not restored.restore(bad),"Invalid prerequisite: "+key)
		check(restored.serialize()==saved,"Failure atomic: "+key)
	for key:String in ["light_x","light_height","board_angle"]:
		var bad:Dictionary=saved.duplicate(true);bad[key]=9999
		check(not restored.restore(bad),"Out of range: "+key)
	var bad:Dictionary=saved.duplicate(true);bad.hints={"align":4};check(not restored.restore(bad),"Hints range")
	bad=saved.duplicate(true);bad.location="future";check(not restored.restore(bad),"Unshipped location rejected")
	bad=saved.duplicate(true);bad.light_x=NAN;check(not restored.restore(bad),"Nonfinite position rejected")
	bad=saved.duplicate(true);bad.notes.append("invented");check(not restored.restore(bad),"Unknown clue rejected")
	var new=State.new();new.photo=true;new.revealed=true;new.photo_placed=true;new.mirror=true;new.laundry_clear=true
	new.move_projection(10000,-100);check(new.light_x==860 and new.light_height==175,"Controls clamp")
	new.move_board(10);check(new.board_angle==.8,"Board clamps")
	new.move_projection(746,320);new.move_board(.24);new.try_open();new.move_projection(500,200);new.move_board(-.5)
	check(new.aligned and new.bridge_ready(),"Opened door cannot be destroyed by experiment")
	check(new.observe("sun") and not new.observe("sun"),"Notebook facts unique")
	print("REBOOT RULES ",checks-failures,"/",checks)
	quit(1 if failures>0 else 0)
