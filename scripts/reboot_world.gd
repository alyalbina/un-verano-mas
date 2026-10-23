extends Node2D
## AStar navigation and character feet origins retained from JourneyScene.
const Panorama=preload("res://scripts/panorama.gd")
var panorama:Node2D
const Journey=preload("res://scripts/journey_episode.gd")
var journey:Node2D
const Episode=preload("res://scripts/summer_episode.gd")
var episode:Node2D
const Character=preload("res://scripts/character.gd")
var game:Node
var scene_id:="courtyard"
var lucia:Node2D
var cat:Node2D
var actors:Node2D
var nav:=AStarGrid2D.new()
var path:=PackedVector2Array()
var pending:=""
var hotspots:Array[Dictionary]=[]
var clock:=0.0
var step_time:=0.0
var dragging:=""
var last_mouse:=Vector2.ZERO
var spot:=Vector2(730,570)
var spot_active:=false
var cat_phase:=0
var cat_busy:=false
var reveal_amount:=0.0
var holding:=false
var archive_display:=false
var bg:Sprite2D
var photo_sprite:Sprite2D
var shadow_layer:Node2D
var curtain:Polygon2D
var echo_alpha:=0.0

func _ready()->void:
	process_mode=Node.PROCESS_MODE_PAUSABLE
	bg=Sprite2D.new();bg.texture=game.art[scene_id];bg.centered=false
	bg.scale=Vector2(1280,720)/bg.texture.get_size();bg.z_index=-100;add_child(bg)
	# Shared drawing occurs behind people and above the painted floor.
	shadow_layer=Node2D.new();shadow_layer.z_index=-20;add_child(shadow_layer)
	shadow_layer.draw.connect(_draw_world)
	actors=Node2D.new();actors.y_sort_enabled=true;add_child(actors)
	lucia=_actor("lucia",Vector2(464,586),320 if scene_id=="kitchen" else 282)
	if scene_id=="kitchen":
		lucia.position=Vector2(408,603);_actor("carmen",Vector2(1140,608),350)
	else:cat=_actor("zhorik",Vector2(685,585),94)
	if scene_id=="courtyard":
		hotspots.assign([
		{"id":"box","name":"Старый ящик","rect":Rect2(205,408,164,123),"foot":Vector2(385,558)},
		{"id":"kitchen","name":"К Кармен","rect":Rect2(18,235,121,270),"foot":Vector2(160,554)},
		{"id":"cord","name":"Шнур и звоночек","rect":Rect2(480,135,79,176),"foot":Vector2(450,553)},
		{"id":"holder","name":"Солнечная полка","rect":Rect2(467,335,149,52),"foot":Vector2(482,549)},
		{"id":"wall","name":"След исчезнувшего порога","rect":Rect2(661,180,172,341),"foot":Vector2(816,560)},
		{"id":"board","name":"Поворотная доска","rect":Rect2(470,529,182,101),"foot":Vector2(477,604)},
		{"id":"cat","name":"Жорик","rect":Rect2(643,491,100,96),"foot":Vector2(610,599)},
		{"id":"tile","name":"Плитка с ласточкой","rect":Rect2(153,337,43,47),"foot":Vector2(199,564)}])
	elif scene_id=="kitchen":
		hotspots.assign([
		{"id":"courtyard","name":"Во дворик","rect":Rect2(41,97,246,411),"foot":Vector2(284,579)},
		{"id":"mirror","name":"Карманное зеркало","rect":Rect2(892,402,116,52),"foot":Vector2(1037,611)},
		{"id":"watermelon","name":"Летний стол","rect":Rect2(600,372,250,91),"foot":Vector2(654,607)},
		{"id":"carmen","name":"Кармен","rect":Rect2(1070,252,141,365),"foot":Vector2(989,609)}])
	elif scene_id=="passage":
		hotspots.assign([
		{"id":"courtyard","name":"Вернуться во дворик","rect":Rect2(18,200,144,330),"foot":Vector2(196,577)},
		{"id":"archive","name":"Два берега одного снимка","rect":Rect2(880,385,243,139),"foot":Vector2(835,609)},
		{"id":"basin","name":"Отражение","rect":Rect2(489,375,250,164),"foot":Vector2(510,605)},
		{"id":"harbor_view","name":"Море за стеной","rect":Rect2(235,186,200,275),"foot":Vector2(375,575)}])
	if scene_id in ["street","plaza"]:
		lucia.position=Vector2(215,589) if scene_id=="street" else Vector2(273,601)
		episode=Episode.new();episode.world=self;episode.game=game;add_child(episode)
	if scene_id in ["workshop","passage","harbor"]:
		journey=Journey.new();journey.world=self;journey.game=game;add_child(journey)
	photo_sprite=Sprite2D.new();photo_sprite.texture=game.art.photograph;photo_sprite.position=Vector2(541,343)
	photo_sprite.scale=Vector2.ONE*0.065;photo_sprite.z_index=2;add_child(photo_sprite)
	_build_nav()
	if game.chapter.positions.has(scene_id):
		var pose:Array=game.chapter.positions[scene_id];lucia.position=nav.get_point_position(_free(Vector2(pose[0],pose[1])))
	if is_wide():
		panorama=Panorama.new();panorama.world=self;panorama.game=game;add_child(panorama)
	else:
		var fixed_camera:=Camera2D.new();fixed_camera.position=Vector2(640,360);fixed_camera.limit_left=0;fixed_camera.limit_right=1280;fixed_camera.limit_top=0;fixed_camera.limit_bottom=720
		add_child(fixed_camera);fixed_camera.make_current();fixed_camera.force_update_scroll()
	sync()

func _actor(id:String,foot:Vector2,height:float)->Node2D:
	var a:=Character.new();a.position=foot;a.name=id.capitalize();actors.add_child(a)
	var frames:Array[Texture2D]=[]
	if id=="lucia":
		for i:int in 4:frames.append(load("res://assets/art/lucia_walk_%d.webp"%i))
	a.setup(game.art[id],height,frames);a.shadow_width=21 if id=="zhorik" else 29
	return a

func is_wide()->bool:return scene_id in ["courtyard","street","plaza"]
func world_bounds()->Rect2:return Rect2(-1280,0,3840,720) if is_wide() else Rect2(0,0,1280,720)
func screen_to_world(p:Vector2)->Vector2:return get_viewport().get_canvas_transform().affine_inverse()*p
func _build_nav()->void:
	nav.region=Rect2i(-80,0,240,45) if is_wide() else Rect2i(0,0,80,45);nav.cell_size=Vector2(16,16);nav.offset=Vector2(8,8)
	nav.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;nav.update()
	for x:int in range(nav.region.position.x,nav.region.end.x):
		for y:int in 45:
			var p:=Vector2(x*16+8,y*16+8)
			var blocked:=p.x<world_bounds().position.x+93 or p.x>world_bounds().end.x-100 or p.y<535 or p.y>620
			if scene_id=="kitchen":blocked=blocked or Rect2(509,535,588,55).has_point(p)
			if scene_id=="plaza":blocked=blocked or Rect2(419,535,416,35).has_point(p) or Rect2(1014,535,137,60).has_point(p)
			if scene_id=="passage":blocked=blocked or Rect2(1008,535,190,74).has_point(p)
			if scene_id=="courtyard":blocked=blocked or Rect2(1120,535,90,63).has_point(p)
			nav.set_point_solid(Vector2i(x,y),blocked)

func _free(p:Vector2)->Vector2i:
	var best:=Vector2i(25,37);var distance:=INF
	for x:int in range(nav.region.position.x,nav.region.end.x):
		for y:int in range(33,39):
			var cell:=Vector2i(x,y)
			if not nav.is_point_solid(cell):
				var d:float=nav.get_point_position(cell).distance_squared_to(p)
				if d<distance:distance=d;best=cell
	return best

func walk_to(p:Vector2,action:String="")->void:
	pending=action;path=nav.get_point_path(_free(lucia.position),_free(p))
	if not path.is_empty():path.remove_at(0)
	if path.is_empty() and pending!="":var a:=pending;pending="";game.world_action(a)
func stop()->void:
	path.clear();pending="";lucia.walking=false;dragging="";spot_active=false
	if is_instance_valid(panorama):panorama.stop()
	if is_instance_valid(episode):episode.stop()
	if is_instance_valid(journey):journey.stop()
func sync()->void:
	if scene_id=="street":bg.texture=game.art.street_open if game.chapter.street_open else game.art.street
	if scene_id=="courtyard":bg.texture=game.art.courtyard_clear if game.chapter.laundry_clear else game.art.courtyard
	photo_sprite.visible=not holding and scene_id=="courtyard" and game.chapter.photo_placed
	if game.chapter.revealed:reveal_amount=1
	if scene_id=="courtyard" and game.chapter.laundry_clear and is_instance_valid(cat):
		cat.position=Vector2(475,354)
	shadow_layer.queue_redraw()

func _process(delta:float)->void:
	clock+=delta
	if not path.is_empty():
		var point:Vector2=path[0]
		if absf(point.x-lucia.position.x)>2:lucia.facing=signf(point.x-lucia.position.x)
		lucia.position=lucia.position.move_toward(point,265*delta);lucia.walking=true
		step_time+=delta
		if step_time>.28:step_time=0;game.audio.play("step")
		if lucia.position.distance_to(point)<2:
			path.remove_at(0)
			if path.is_empty():
				lucia.walking=false
				if pending!="":var a:=pending;pending="";game.world_action(a)
				else:game._save_game()
	else:lucia.walking=false
	lucia.scale=Vector2.ONE*lerpf(.94,1.04,clampf((lucia.position.y-535)/85,0,1))
	if holding:
		photo_sprite.visible=archive_display
	elif scene_id=="courtyard":photo_sprite.position=Vector2(541,343);photo_sprite.scale=Vector2.ONE*.045
	if scene_id=="courtyard" and is_instance_valid(cat):
		for h:Dictionary in hotspots:
			if h.id=="cat":h.rect=Rect2(cat.position-Vector2(44,94),Vector2(88,94))
	shadow_layer.queue_redraw()

func projection_rect()->Rect2:
	var st=game.chapter
	return Rect2(st.light_x-75,520-st.light_height,150,st.light_height)

func _draw_world()->void:
	if scene_id=="courtyard":
		# A surviving threshold supplies spatial evidence instead of a numeric lock.
		shadow_layer.draw_line(Vector2(671,520),Vector2(821,520),Color("b99a74"),6,true)
		shadow_layer.draw_line(Vector2(671,520),Vector2(671,200),Color(.62,.50,.37,.20),2,true)
		shadow_layer.draw_line(Vector2(821,520),Vector2(821,200),Color(.62,.50,.37,.20),2,true)
		var center:=Vector2(551,584);var a:float=game.chapter.board_angle
		var ends:=PackedVector2Array([center+Vector2(-72,-10).rotated(a),center+Vector2(72,-10).rotated(a),center+Vector2(72,10).rotated(a),center+Vector2(-72,10).rotated(a)])
		shadow_layer.draw_colored_polygon(ends,Color("987346"));shadow_layer.draw_polyline(ends+PackedVector2Array([ends[0]]),Color("684e36"),2,true)
		shadow_layer.draw_circle(center,6,Color("d1ac61"))
		var end:=Vector2(746,520)+Vector2(185,126)*(a-.24)
		if game.chapter.photo_placed:
			shadow_layer.draw_line(center+Vector2(59,0).rotated(a),end,Color(.23,.22,.19,.28),19,true)
		else:shadow_layer.draw_line(center+Vector2(59,0).rotated(a),center+Vector2(91,-9).rotated(a),Color(.23,.22,.19,.22),17,true)
		for grain:int in 3:
			var points:=PackedVector2Array()
			for j:int in 8:points.append(center+Vector2(-63+j*18,-5+grain*5+sin(j*1.3+grain)*1.2).rotated(a))
			shadow_layer.draw_polyline(points,Color(.34,.25,.15,.32),1,true)
		if game.chapter.photo_placed or reveal_amount>0:
			var r:=projection_rect()
			var drift:=0.0 if game.chapter.photo_placed else sin(clock*1.2)*28
			r.position.x+=drift
			if game.chapter.opened:
				shadow_layer.draw_style_box(game.ui.style(Color("edd0a4")),r.grow(7))
				var tex:Texture2D=game.art.passage
				var sw:float=tex.get_height()*r.size.x/r.size.y
				shadow_layer.draw_texture_rect_region(tex,r,Rect2((tex.get_width()-sw)*.5,0,sw,tex.get_height()))
			else:
				var col:=Color(.24,.23,.19,.25*reveal_amount)
				shadow_layer.draw_rect(r.grow(5),Color(col.r,col.g,col.b,.10*reveal_amount))
				shadow_layer.draw_rect(r,col)
				shadow_layer.draw_line(r.position+Vector2(11,12),r.position+Vector2(11,r.size.y-9),Color(.84,.72,.51,.21),2,true)
				shadow_layer.draw_circle(r.position+Vector2(105,r.size.y*.57),5,Color(.22,.23,.18,.38))
				if not game.chapter.laundry_clear:
					var gap:=Rect2(r.position+Vector2(-8,68),Vector2(r.size.x+16,64))
					var ratio:Vector2=game.art.courtyard.get_size()/Vector2(1280,720)
					shadow_layer.draw_texture_rect_region(game.art.courtyard,gap,Rect2(gap.position*ratio,gap.size*ratio))
			if game.chapter.photo_placed and not game.chapter.opened:
				# The photo can slide and tilt on the shelf, exact geometry remains visible.
				shadow_layer.draw_line(Vector2(495,404),Vector2(604,404),Color("8a6b47"),4,true)
				var handle:=Vector2(495+(game.chapter.light_x-490)/370*109,404-(game.chapter.light_height-175)/200*48)
				shadow_layer.draw_line(Vector2(handle.x,405),handle,Color("a37e4f"),3,true)
				shadow_layer.draw_circle(handle,9,Color("e3ba62"));shadow_layer.draw_arc(handle,9,0,TAU,32,Color("76562d"),2,true)
			if game.chapter.aligned and not game.chapter.opened:
				shadow_layer.draw_line(Vector2(671,520),Vector2(821,520),Color("fff1c6"),4,true)
		if spot_active:
			shadow_layer.draw_circle(spot,26,Color(1,.91,.55,.14));shadow_layer.draw_circle(spot,16,Color(1,.97,.70,.43));shadow_layer.draw_circle(spot,6,Color(1,1,.91,.8))
	elif scene_id=="kitchen" and not game.chapter.mirror:
		shadow_layer.draw_circle(Vector2(934,426),19,Color("8a6b47"));shadow_layer.draw_circle(Vector2(934,426),14,Color("cfdfd6"))
		shadow_layer.draw_line(Vector2(940,443),Vector2(952,458),Color("8a6b47"),7,true)
	elif scene_id=="passage":
		# A ripple contains a different direction of sunlight, no generic particles.
		for i:int in 3:shadow_layer.draw_arc(Vector2(630,469),26+i*12+sin(clock)*3,0,TAU,64,Color(.87,.93,.71,.23),2,true)

func tooltip_at(p:Vector2)->String:
	if is_instance_valid(journey):
		var value:String=journey.tooltip(p)
		if value!="":return value
	if is_instance_valid(episode):
		var value:String=episode.tooltip(p)
		if value!="":return value
	if scene_id=="courtyard" and game.chapter.photo_placed and Rect2(480,340,139,78).has_point(p) and not game.chapter.opened:return "Переместить и наклонить фотографию · перетащи"
	if scene_id=="courtyard" and spot_active:return "Вести солнечный блик · перетащи"
	for h:Dictionary in hotspots:
		if h.rect.has_point(p):return h.name
	return ""

func _input(event:InputEvent)->void:
	if game.modal!="" or game.transitioning:return
	if is_instance_valid(panorama) and panorama.key_input(event):get_viewport().set_input_as_handled()

func _unhandled_input(event:InputEvent)->void:
	if game.modal!="" or game.transitioning:return
	if event is InputEventMouse:
		event=event.duplicate();event.position=screen_to_world(event.position);event.global_position=event.position
	if is_instance_valid(journey) and journey.input(event):get_viewport().set_input_as_handled();return
	if is_instance_valid(episode) and episode.input(event):get_viewport().set_input_as_handled();return
	if event is InputEventMouseMotion and dragging!="":
		var p:Vector2=event.position
		if dragging=="projection":game.chapter.move_projection(game.chapter.light_x+(p.x-last_mouse.x)*2.6,game.chapter.light_height-(p.y-last_mouse.y)*2.3)
		elif dragging=="board":game.chapter.move_board((p.y-584)/75.0)
		else:_move_spot(p)
		last_mouse=p;get_viewport().set_input_as_handled();return
	if not event is InputEventMouseButton or event.button_index!=MOUSE_BUTTON_LEFT:return
	if not event.pressed:
		if dragging!="":dragging="";game.check_progress();game._save_game()
		return
	var p:Vector2=event.position
	if p.y<95 or p.y>630:return
	if scene_id=="courtyard" and not game.chapter.opened:
		if game.selected_item=="mirror":
			if not game.chapter.photo_placed:game.message="Сначала выясним, что делает фотография на солнце.";return
			spot_active=true;dragging="spot";last_mouse=p;_move_spot(p);get_viewport().set_input_as_handled();return
		if game.chapter.photo_placed and Rect2(480,340,139,78).has_point(p):
			dragging="projection";last_mouse=p;game.selected_item="";game.message="Двигай снимок по полке и наклоняй его. Тень меняется вместе с ним.";get_viewport().set_input_as_handled();return
		if game.chapter.photo_placed and Rect2(470,529,182,101).has_point(p):
			dragging="board";last_mouse=p;game.message="Доска вращается вокруг гвоздя. Следи за концом её тени.";get_viewport().set_input_as_handled();return
	for h:Dictionary in hotspots:
		if h.rect.has_point(p):walk_to(h.foot,h.id);get_viewport().set_input_as_handled();return
	if p.y>=535:walk_to(p)

func _move_spot(p:Vector2)->void:
	var travel:=p.distance_to(spot);spot=Vector2(clampf(p.x,180,1150),clampf(p.y,230,615))
	if cat_busy or game.chapter.laundry_clear or travel<5:return
	var targets:=[Vector2(351,507),Vector2(513,353),Vector2(545,250)]
	if spot.distance_to(targets[cat_phase])<48:
		cat_busy=true;cat.shadow_opacity=0.0;game.message=["Жорик следит за бликом на ящике…","Полка! Кот нашёл обходной путь.","Вместо блика Жорик поймал шнур."][cat_phase]
		cat.idle_texture=game.art.zhorik_pounce
		var t:=create_tween();t.tween_property(cat,"position",[Vector2(351,430),Vector2(513,354),Vector2(535,268)][cat_phase],.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.finished.connect(func():
			cat_busy=false;cat.shadow_opacity=.15;cat_phase+=1
			if cat_phase==3:
				cat_phase=0;spot_active=false;dragging="";game.selected_item="";game.cat_pulled()
			else:cat.react("inspect"))
