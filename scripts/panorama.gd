extends Node2D
## Three real screens, unchanged actor scale and a screen-fixed CanvasLayer HUD.
var world:Node2D
var game:Node
var seam_layer:Node2D
var camera:Camera2D
var direction:=0
var following_cat:=false
var cat_path:=PackedVector2Array()
var cat_timer:=0.0
var cat_jumping:=false
const SIDES={
	"courtyard":["courtyard_breakfast","courtyard_sundial"],
	"street":["street_helados","street_lookout"],
	"plaza":["plaza_cafe","plaza_coast"]}
const NAMES={"courtyard_breakfast":"Стол под аркадой","courtyard_sundial":"Солнечные часы в саду","street_helados":"Маленькая heladería","street_lookout":"Море за поворотом","plaza_cafe":"Кафе под апельсиновыми деревьями","plaza_coast":"Панорама побережья"}
const LINES={
	"courtyard_breakfast":"Томат, оливковое масло и тёплый хлеб. Кармен оставила завтрак в тени аркады.",
	"courtyard_sundial":"На солнечных часах полдень. Только тень нашей исчезнувшей двери живёт по другому времени.",
	"street_helados":"Маленькая heladería. Мороженое напоминает о прогулке по старому городу Марбельи.",
	"street_lookout":"За поворотом снова море. Теперь видно, куда тянется исчезнувшая дорога.",
	"plaza_cafe":"Тень апельсиновых деревьев, голуби и музыка вдалеке. Можно просто задержаться здесь.",
	"plaza_coast":"С этой стороны площадь смотрит на побережье. Гитарист остался далеко за спиной."}

func _ready()->void:
	for i:int in 2:
		var sprite:=Sprite2D.new();sprite.centered=false;sprite.texture=game.art[world.scene_id+("_left" if i==0 else "_right")]
		sprite.scale=Vector2(1280,720)/sprite.texture.get_size();sprite.position=Vector2(-1280 if i==0 else 1280,0);sprite.z_index=-100;add_child(sprite)
	var ids:Array=SIDES[world.scene_id]
	var rectangles:Dictionary={"courtyard":[Rect2(-1160,320,390,205),Rect2(1800,250,255,240)],"street":[Rect2(-983,215,380,270),Rect2(1640,180,600,340)],"plaza":[Rect2(-1200,280,670,240),Rect2(1610,255,350,270)]}
	var feet:Dictionary={"courtyard":[Vector2(-990,589),Vector2(1930,589)],"street":[Vector2(-760,589),Vector2(1920,589)],"plaza":[Vector2(-850,589),Vector2(1880,589)]}
	world.hotspots.append({"id":ids[0],"name":NAMES[ids[0]],"rect":rectangles[world.scene_id][0],"foot":feet[world.scene_id][0]})
	world.hotspots.append({"id":ids[1],"name":NAMES[ids[1]],"rect":rectangles[world.scene_id][1],"foot":feet[world.scene_id][1]})
	seam_layer=Node2D.new();seam_layer.z_index=-90;add_child(seam_layer);seam_layer.draw.connect(_draw_seams)
	camera=Camera2D.new();camera.name="JourneyCamera";camera.position=Vector2(target_x(),360)
	camera.limit_left=-1280;camera.limit_right=2560;camera.limit_top=0;camera.limit_bottom=720
	camera.position_smoothing_enabled=false;add_child(camera);camera.make_current();camera.force_update_scroll()

func target_x()->float:
	var x:float=world.lucia.position.x
	var target:=640.0
	if x<300:target=x+340
	elif x>980:target=x-340
	return clampf(target,-640,1920)

func _process(delta:float)->void:
	var dragging:bool=world.dragging!="" or (is_instance_valid(world.episode) and world.episode.dragging)
	if not game.transitioning and game.modal=="" and not dragging:
		camera.position.x=lerpf(camera.position.x,target_x(),1-exp(-7.0*delta));camera.force_update_scroll()
		if direction!=0 and world.path.is_empty():walk_side(direction)
	seam_layer.queue_redraw()
	_update_cat(delta)

func walk_side(value:int)->void:
	world.walk_to(Vector2(2460 if value>0 else -1187,world.lucia.position.y))

func stop()->void:direction=0

func key_input(event:InputEvent)->bool:
	if not event is InputEventKey or not event.keycode in [KEY_LEFT,KEY_RIGHT]:return false
	if event.echo:return true
	if event.pressed:
		direction=-1 if event.keycode==KEY_LEFT else 1;walk_side(direction)
	else:
		direction=0;world.stop();game._save_game()
	return true

func action(id:String)->bool:
	if not LINES.has(id):return false
	game._note(id);world.lucia.react("happy" if id in ["courtyard_breakfast","street_helados","plaza_cafe"] else "inspect")
	game.message=LINES[id];game._save_game();return true

func _update_cat(delta:float)->void:
	if not is_instance_valid(world.cat) or world.cat_busy or game.transitioning or game.modal!="":return
	var outside:bool=world.lucia.position.x<40 or world.lucia.position.x>1240
	if world.scene_id=="courtyard" and not game.chapter.laundry_clear:return
	if outside:following_cat=true
	if not following_cat or cat_jumping:return
	if world.cat.position.y<530:
		cat_jumping=true
		var t:=world.create_tween();t.tween_property(world.cat,"position",Vector2(world.cat.position.x,586),.55).set_trans(Tween.TRANS_QUAD)
		t.finished.connect(func():cat_jumping=false)
		return
	cat_timer-=delta
	if cat_timer<=0:
		cat_timer=.45
		if world.cat.position.distance_to(world.lucia.position)>150:
			var target:Vector2=world.lucia.position+Vector2(-110*world.lucia.facing,9)
			cat_path=world.nav.get_point_path(world._free(world.cat.position),world._free(target))
			if not cat_path.is_empty():cat_path.remove_at(0)
	if not cat_path.is_empty():
		var p:Vector2=cat_path[0];world.cat.facing=signf(p.x-world.cat.position.x) if absf(p.x-world.cat.position.x)>2 else world.cat.facing
		world.cat.position=world.cat.position.move_toward(p,295*delta)
		if world.cat.position.distance_to(p)<2:cat_path.remove_at(0)
	queue_redraw()


func _draw_seams()->void:
	# Painted pilasters frame the joins; puzzle geometry starts beyond x=16.
	var tex:Texture2D=game.art.courtyard_left
	var source:=Rect2(tex.get_width()*.942,0,tex.get_width()*.039,tex.get_height()*.743)
	for x:float in [0.0,1280.0]:
		seam_layer.draw_texture_rect_region(tex,Rect2(x-16,0,32,535),source)
		seam_layer.draw_line(Vector2(x+16,0),Vector2(x+16,535),Color(.27,.19,.12,.16),2,true)
