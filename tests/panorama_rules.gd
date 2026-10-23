extends SceneTree
const State=preload("res://scripts/reboot_state.gd")
var count:=0
var failed:=0
func check(ok:bool,title:String)->void:
	count+=1
	if not ok:failed+=1;push_error(title)
func _init()->void:
	var s=State.new();s.positions={"courtyard":[-1160,584],"kitchen":[408,603]}
	var raw:Dictionary=s.serialize();var r=State.new()
	check(r.restore(JSON.parse_string(JSON.stringify(raw))),"Distant pose roundtrip")
	check(r.positions==s.positions,"Pose numeric types normalized")
	for value:Variant in [[-1400,584],[2600,584],[500,300],[500,700],[NAN,580],[INF,580],[false,580],[500],[500,580,1]]:
		var bad:Dictionary=raw.duplicate(true);bad.positions.courtyard=value
		check(not r.restore(bad),"Invalid pose rejected")
		check(r.positions==s.positions,"Rejected pose restore stays atomic")
	var bad:Dictionary=raw.duplicate(true);bad.positions.kitchen=[-500,580]
	check(not r.restore(bad),"Indoor pose cannot use outdoor range")
	bad=raw.duplicate(true);bad.positions.unknown=[500,580];check(not r.restore(bad),"Unknown scene pose rejected")
	bad=raw.duplicate(true);bad.positions=[];check(not r.restore(bad),"Wrong container rejected")
	var older:Dictionary=raw.duplicate(true);older.erase("positions")
	check(r.restore(older) and r.positions.is_empty(),"v0.6 save without poses migrates")
	print("PANORAMA RULES ",count-failed,"/",count);quit(1 if failed else 0)
