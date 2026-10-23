extends RefCounted
## Canonical truth; visuals never own progression. All experiments remain reversible.
const PLACES = ["courtyard","kitchen","passage","street","plaza","workshop","harbor"]
const WORKSHOP_BOOL = ["spool_moved","belt_taken","belt_installed","back_seen","workshop_linked","frame_fixed","frame_taken","frame_placed","route_open","departed"]
var spool_moved := false
var belt_taken := false
var belt_installed := false
var back_seen := false
var workshop_linked := false
var frame_fixed := false
var frame_taken := false
var frame_placed := false
var route_open := false
var departed := false
var belt_tension := 0
var idle_sector := 0
var route_anchor := "none"
var route_angle := 2.4
var route_loop := true
const EXTRA_BOOL = ["jug","jug_filled","drain_held","water_on","mirror_mounted","seen_arch","seen_reflection","street_open","cup_filled","heard_motif","echo_fixed","connection_found"]
var jug := false
var jug_filled := false
var drain_held := false
var water_on := false
var mirror_mounted := false
var seen_arch := false
var seen_reflection := false
var street_open := false
var cup_filled := false
var heard_motif := false
var echo_fixed := false
var connection_found := false
var reflection_angle := -0.55
var valves: Array[bool] = [true, false, false]

var positions:Dictionary={}
var location := "courtyard"
var photo := false
var revealed := false
var mirror := false
var photo_placed := false
var laundry_clear := false
var aligned := false
var opened := false
var entered := false
var complete := false
var light_x := 570.0
var light_height := 200.0
var board_angle := -0.45
var notes: Array[String] = []
var hints: Dictionary = {}
var muted := false
var visited: Array[String] = ["courtyard"]

func inventory() -> Array[String]:
	var result: Array[String] = []
	if photo: result.append("photograph")
	if mirror and not mirror_mounted: result.append("mirror")
	if jug and not drain_held: result.append("jug")
	if belt_taken and not belt_installed: result.append("belt")
	if frame_taken and not frame_placed: result.append("frame")
	return result

func observe(id: String) -> bool:
	if id in notes:return false
	notes.append(id); return true

func move_projection(x: float, height: float) -> void:
	if not photo_placed or opened:return
	light_x=snappedf(clampf(x,490,860),.01);light_height=snappedf(clampf(height,175,375),.01)
	# Two independent physical dimensions, feedback is the actual geometry.
	aligned=laundry_clear and absf(light_x-746.0)<13.0 and absf(light_height-320.0)<12.0

func move_board(angle:float) -> void:
	if opened:return
	board_angle=snappedf(clampf(angle,-0.8,0.8),.001)

func bridge_ready() -> bool:
	return aligned and absf(board_angle-0.24)<0.07

func try_open() -> bool:
	if not bridge_ready():return false
	opened=true;observe("threshold");return true

func can_enter(id:String) -> bool:
	return id in ["courtyard","kitchen"] or (id=="passage" and opened) or (id in ["street","plaza"] and complete) or (id=="workshop" and street_open) or (id=="harbor" and departed)

func visit(id:String) -> void:
	if not can_enter(id):return
	location=id
	if not id in visited:visited.append(id)
	if id=="passage":entered=true

func stage() -> String:
	if departed:return "harbor"
	if route_open:return "departure"
	if frame_fixed:return "route"
	if location=="workshop":return "frame"
	if connection_found:return "connection"
	if complete and location=="street":
		if street_open:return "street_done"
		if not drain_held or not water_on:return "water"
		return "reflection"
	if complete and location=="plaza":return "echo_done" if echo_fixed else "music"
	if complete:return "after"
	if entered:return "archive"
	if opened:return "entry"
	if aligned:return "bridge"
	if photo_placed and laundry_clear:return "align"
	if photo_placed:return "cat"
	if photo:return "photo"
	return "find"

func _base_serialize() -> Dictionary:
	return {"schema":5,"location":location,"photo":photo,"revealed":revealed,"mirror":mirror,"photo_placed":photo_placed,"laundry_clear":laundry_clear,"aligned":aligned,"opened":opened,"entered":entered,"complete":complete,"light_x":light_x,"light_height":light_height,"board_angle":board_angle,"notes":notes.duplicate(),"hints":hints.duplicate(),"muted":muted,"visited":visited.duplicate()}

func _restore_base(raw:Dictionary) -> bool:
	if raw.get("schema")!=5:return false
	for k:String in ["photo","revealed","mirror","photo_placed","laundry_clear","aligned","opened","entered","complete","muted"]:
		if not raw.get(k) is bool:return false
	if not raw.get("location") in PLACES:return false
	for k:String in ["light_x","light_height","board_angle"]:
		if not (raw.get(k) is float or raw.get(k) is int) or not is_finite(float(raw[k])):return false
	if raw.light_x<490 or raw.light_x>860 or raw.light_height<175 or raw.light_height>375 or absf(raw.board_angle)>0.8:return false
	if not raw.get("notes") is Array or not raw.get("hints") is Dictionary or not raw.get("visited") is Array:return false
	for n:Variant in raw.notes:
		if not n is String or not n in ["wall","photo","sun","cord","mirror","cat","threshold","archive","watermelon","carmen","tile","street_sign","arch_chip","still_water","water_flow","mirror_mount","reflection_join","fountain_routes","motif","echo_anchor","connection","guitar","olives","courtyard_breakfast","courtyard_sundial","street_helados","street_lookout","plaza_cafe","plaza_coast","workshop_mechanism","workshop_back","workshop_belt","workshop_loop","workshop_ledger","frame_fixed","route_map","route_anchor","route_open","harbor_arrival","harbor_net","harbor_icecream"]:return false
	for h:Variant in raw.hints:
		if not h in ["find","photo","cat","align","bridge","entry","archive","after","water","reflection","street_done","music","echo_done","connection","frame","route","departure","harbor"]:return false
		if not (raw.hints[h] is float or raw.hints[h] is int) or int(raw.hints[h])<0 or int(raw.hints[h])>3:return false
	for v:Variant in raw.visited:
		if not v in PLACES:return false
	if not "courtyard" in raw.visited or not raw.location in raw.visited:return false
	if raw.photo_placed and not (raw.photo and raw.revealed):return false
	if raw.revealed and not raw.photo:return false
	if raw.laundry_clear and not raw.mirror:return false
	var correct:bool=raw.laundry_clear and absf(raw.light_x-746.0)<13 and absf(raw.light_height-320.0)<12
	if raw.aligned!=correct:return false
	if raw.opened and not (raw.aligned and raw.photo_placed and absf(raw.board_angle-0.24)<0.07):return false
	if raw.entered and not raw.opened:return false
	if raw.complete and not raw.entered:return false
	if raw.location=="passage" and not raw.opened:return false
	if raw.location in ["street","plaza","workshop","harbor"] and not raw.complete:return false
	# Commit only after all invariants have passed.
	for k:String in ["location","photo","revealed","mirror","photo_placed","laundry_clear","aligned","opened","entered","complete","light_x","light_height","board_angle","muted"]:set(k,raw[k])
	notes.assign(raw.notes);visited.assign(raw.visited);hints=raw.hints.duplicate()
	for key:Variant in hints:hints[key]=int(hints[key])
	return true


func still_water() -> bool:
	return water_on and drain_held

func reflection_matches() -> bool:
	return still_water() and mirror_mounted and seen_arch and seen_reflection and absf(reflection_angle-0.28)<0.055

func turn_mirror(angle:float) -> void:
	if not mirror_mounted or street_open:return
	reflection_angle=snappedf(clampf(angle,-0.85,0.85),0.001)

func hold_drain() -> bool:
	if not jug or not jug_filled:return false
	drain_held=not drain_held
	return true

func try_reflection() -> bool:
	if not reflection_matches():return false
	street_open=true;observe("reflection_join");return true

func toggle_valve(index:int) -> void:
	if index<0 or index>2:return
	valves[index]=not valves[index]

func long_route() -> bool:
	return cup_filled and valves==[false,true,false]

func try_echo() -> bool:
	if not long_route() or not heard_motif:return false
	echo_fixed=true;observe("echo_anchor");return true

func serialize() -> Dictionary:
	var raw:Dictionary=_base_serialize();raw.schema=7
	for key:String in EXTRA_BOOL+WORKSHOP_BOOL:raw[key]=get(key)
	raw.belt_tension=belt_tension;raw.idle_sector=idle_sector;raw.route_anchor=route_anchor;raw.route_angle=route_angle;raw.route_loop=route_loop
	raw.positions=positions.duplicate(true);raw.reflection_angle=reflection_angle;raw.valves=valves.duplicate()
	return raw

func restore(raw:Dictionary) -> bool:
	if raw.get("schema")!=5 and raw.get("schema")!=6 and raw.get("schema")!=7:return false
	var candidate:Dictionary=raw.duplicate(true)
	var poses:Variant=candidate.get("positions",{})
	if not poses is Dictionary:return false
	var clean:Dictionary={}
	for place:Variant in poses:
		if not place in PLACES or not poses[place] is Array or poses[place].size()!=2:return false
		for value:Variant in poses[place]:
			if not (value is int or value is float) or not is_finite(float(value)):return false
		var wide:bool=place in ["courtyard","street","plaza"]
		var x:float=poses[place][0];var y:float=poses[place][1]
		if x<(-1187 if wide else 93) or x>(2460 if wide else 1180) or y<535 or y>620:return false
		clean[place]=[int(x),int(y)]
	if raw.schema==5:
		# Migration is read-only on the original v0.5 save; new fields start fresh.
		for key:String in EXTRA_BOOL:candidate[key]=false
		candidate.reflection_angle=-0.55;candidate.valves=[true,false,false]
	if raw.schema==5 or raw.schema==6:
		for key:String in WORKSHOP_BOOL:candidate[key]=false
		candidate.belt_tension=0;candidate.idle_sector=0;candidate.route_anchor="none";candidate.route_angle=2.4;candidate.route_loop=true
	for key:String in WORKSHOP_BOOL:
		if not candidate.get(key) is bool:return false
	for key:String in ["belt_tension","idle_sector"]:
		if not (candidate.get(key) is int or candidate.get(key) is float) or not is_finite(float(candidate[key])) or float(candidate[key])!=int(candidate[key]):return false
	if candidate.belt_tension<0 or candidate.belt_tension>2 or candidate.idle_sector<0 or candidate.idle_sector>7:return false
	if not candidate.get("route_anchor") in ["none","courtyard","lake"] or not candidate.get("route_loop") is bool:return false
	if not (candidate.get("route_angle") is float or candidate.get("route_angle") is int) or not is_finite(float(candidate.route_angle)) or absf(candidate.route_angle)>PI:return false
	if candidate.belt_taken and not candidate.spool_moved:return false
	if candidate.belt_installed and not candidate.belt_taken:return false
	if candidate.frame_fixed and not (candidate.belt_installed and candidate.back_seen and candidate.workshop_linked and candidate.echo_fixed and candidate.connection_found):return false
	if candidate.frame_fixed and (candidate.belt_tension!=1 or candidate.idle_sector!=4):return false
	if candidate.frame_taken and not candidate.frame_fixed:return false
	if candidate.frame_placed and not candidate.frame_taken:return false
	if candidate.route_open and not (candidate.frame_placed and candidate.route_anchor=="courtyard" and not candidate.route_loop and absf(candidate.route_angle+0.72)<0.18):return false
	if candidate.departed and not candidate.route_open:return false
	for key:String in WORKSHOP_BOOL:
		if candidate[key] and not candidate.street_open:return false
	if candidate.location=="workshop" and not candidate.street_open:return false
	if candidate.location=="harbor" and not candidate.departed:return false
	for key:String in EXTRA_BOOL:
		if not candidate.get(key) is bool:return false
	if not (candidate.get("reflection_angle") is float or candidate.get("reflection_angle") is int):return false
	if not is_finite(float(candidate.reflection_angle)) or absf(candidate.reflection_angle)>0.85:return false
	if not candidate.get("valves") is Array or candidate.valves.size()!=3:return false
	for value:Variant in candidate.valves:
		if not value is bool:return false
	if candidate.jug_filled and not candidate.jug:return false
	if candidate.drain_held and not candidate.jug_filled:return false
	if candidate.mirror_mounted and not candidate.mirror:return false
	if candidate.street_open and not (candidate.seen_arch and candidate.seen_reflection and candidate.jug_filled):return false
	if candidate.cup_filled and not candidate.jug_filled:return false
	if candidate.echo_fixed and not (candidate.cup_filled and candidate.heard_motif):return false
	if candidate.connection_found and not (candidate.street_open and candidate.echo_fixed):return false
	for key:String in EXTRA_BOOL:
		if candidate[key] and not candidate.complete:return false
	if (candidate.water_on or candidate.seen_arch or candidate.heard_motif) and not candidate.complete:return false
	candidate.schema=5
	if not _restore_base(candidate):return false
	for key:String in EXTRA_BOOL+WORKSHOP_BOOL:set(key,candidate[key])
	belt_tension=int(candidate.belt_tension);idle_sector=int(candidate.idle_sector);route_anchor=candidate.route_anchor;route_angle=float(candidate.route_angle);route_loop=candidate.route_loop
	reflection_angle=float(candidate.reflection_angle);valves.assign(candidate.valves);positions=clean
	return true

func try_frame() -> bool:
	if not (connection_found and belt_installed and back_seen and workshop_linked and echo_fixed and belt_tension==1 and idle_sector==4):return false
	frame_fixed=true;observe("frame_fixed");return true

func turn_sector() -> void:
	if not frame_fixed:idle_sector=(idle_sector+1)%8

func tighten_belt() -> void:
	if belt_installed and not frame_fixed:belt_tension=(belt_tension+1)%3

func aim_route(angle:float) -> void:
	if frame_placed and not route_open:route_angle=clampf(angle,-PI,PI)

func try_route() -> bool:
	if not (frame_placed and route_anchor=="courtyard" and not route_loop and absf(route_angle+0.72)<0.18):return false
	route_open=true;observe("route_open");return true
