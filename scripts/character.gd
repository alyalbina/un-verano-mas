extends Node2D
## Feet are the origin. Idle/reaction use Tween; locomotion uses a four-frame atlas.
var sprite: Sprite2D
var walking := false
var facing := 1.0
var clock := 0.0
var base_height := 230.0
var walk_frames: Array[Texture2D] = []
var idle_texture: Texture2D
var reaction: Tween
var shadow_width:=28.0
var shadow_opacity:=0.15

func setup(texture: Texture2D, height: float, frames: Array[Texture2D] = []) -> void:
	idle_texture = texture
	base_height = height
	walk_frames = frames
	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	add_child(sprite)
	_fit(texture)

func _fit(texture: Texture2D) -> void:
	var ratio := base_height / float(texture.get_height())
	sprite.scale = Vector2(ratio, ratio)
	sprite.position = Vector2(-float(texture.get_width()) * ratio * 0.5, -base_height)

func _process(delta: float) -> void:
	if sprite == null:
		return
	clock += delta
	var tex: Texture2D = idle_texture
	if walking and not walk_frames.is_empty():
		tex = walk_frames[int(clock * 8.0) % walk_frames.size()]
	if sprite.texture != tex:
		sprite.texture = tex
		_fit(tex)
	if reaction == null or not reaction.is_running():
		rotation = sin(clock * (9.0 if walking else 1.8)) * (0.012 if walking else 0.003)
		sprite.position.y = -base_height + sin(clock * (16.0 if walking else 2.0)) * (1.6 if walking else 0.7)
	sprite.flip_h = facing < 0.0
	queue_redraw()

func _draw()->void:
	draw_set_transform(Vector2(3,-1),0.0,Vector2(1.0,0.22))
	draw_circle(Vector2.ZERO,shadow_width*1.25,Color(0.21,0.17,0.15,shadow_opacity*0.22))
	draw_circle(Vector2.ZERO,shadow_width,Color(0.21,0.17,0.15,shadow_opacity*0.38))
	draw_circle(Vector2.ZERO,shadow_width*0.72,Color(0.21,0.17,0.15,shadow_opacity*0.35))
	draw_set_transform(Vector2.ZERO)

func react(kind: String) -> void:
	if reaction != null:
		reaction.kill()
	reaction = create_tween()
	if kind == "pickup":
		reaction.tween_property(self, "rotation", 0.15 * facing, 0.18)
		reaction.tween_property(self, "rotation", 0.0, 0.24)
	elif kind == "happy":
		reaction.tween_property(sprite, "position:y", -base_height - 12.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		reaction.tween_property(sprite, "position:y", -base_height, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		reaction.tween_property(self, "rotation", -0.05, 0.16)
		reaction.tween_property(self, "rotation", 0.05, 0.20)
		reaction.tween_property(self, "rotation", 0.0, 0.18)
