extends Node
## Original synthesized temporary effects; replace with recorded audio in a later sprint.
var muted := false
var players: Array[AudioStreamPlayer] = []
var next_player := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in 6:
		var player := AudioStreamPlayer.new()
		add_child(player)
		players.append(player)

func _exit_tree() -> void:
	# Release active playback before the engine tears down audio resources.
	for player: AudioStreamPlayer in players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null

func play(cue: String) -> void:
	if muted:
		return
	var player := players[next_player]
	next_player = (next_player + 1) % players.size()
	player.stream = load("res://assets/audio/" + cue + ".wav")
	player.volume_db = -10.0 if cue != "step" else -20.0
	player.pitch_scale = randf_range(0.94, 1.06) if cue == "step" else 1.0
	player.play()

func toggle_mute() -> void:
	muted = not muted
	if muted:
		for player: AudioStreamPlayer in players:
			player.stop()
