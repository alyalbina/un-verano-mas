extends "res://tests/episode_playthrough.gd"
func run()->void:
 if not "--qa" in OS.get_cmdline_user_args():push_error("Demo requires --qa to protect player saves");quit(2);return
 game=load("res://scenes/reboot.tscn").instantiate();root.add_child(game);await frames(20)
 game.chapter=unlocked();game.chapter.visit("street");game.chapter.positions.street=[-1100,584];game._mount("street");await frames(20)
 game.message="От heladería к морю · камера следует за Лусией"
 var f:=FileAccess.open("res://tests/demo_ready",FileAccess.WRITE);f.store_string("ready");f.close()
 await create_timer(.9).timeout
 var e:=InputEventKey.new();e.keycode=KEY_RIGHT;e.pressed=true;Input.parse_input_event(e)
 await create_timer(17.6).timeout
 e=InputEventKey.new();e.keycode=KEY_RIGHT;e.pressed=false;Input.parse_input_event(e)
 game._stop_audio();await create_timer(.3).timeout;quit()
