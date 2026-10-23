extends Node
## Short deterministic beat sequence; gameplay commits belong to the receiver.
signal beat(id:String)
var running := false
var elapsed := 0.0
var cursor := 0
var script_beats: Array = []
var duration := 0.0
var speed := 1.0
signal finished

func _ready() -> void:process_mode=Node.PROCESS_MODE_ALWAYS
func start(beats:Array,seconds:float) -> void:
	script_beats=beats;duration=seconds;cursor=0;elapsed=0;running=true
func _process(delta:float) -> void:
	if not running or get_tree().paused:return
	elapsed+=delta*speed
	while cursor<script_beats.size() and elapsed>=script_beats[cursor][0]:
		beat.emit(script_beats[cursor][1]);cursor+=1
	if elapsed>=duration:running=false;finished.emit()
func finish_now() -> void:
	if not running:return
	while cursor<script_beats.size():beat.emit(script_beats[cursor][1]);cursor+=1
	running=false;finished.emit()
