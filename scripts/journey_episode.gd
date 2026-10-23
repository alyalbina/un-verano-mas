extends Node2D
## Workshop transmission and the material route in the existing loggia.
var world:Node2D
var game:Node
var clock:=0.0
var testing:=false
var back_view:=false
var dragging:=false
var route_visible:=false
var font:=ThemeDB.fallback_font
const GEAR=Vector2(746,254)
const DRIVE=Vector2(596,316)
const LOOP=Vector2(664,254)
const OUT=Vector2(814,220)
const MAP_CENTER=Vector2(831,381)
const EXTRA_NOTES={
	"workshop_mechanism":"Ремень передаёт движение от ручки. Холостой сектор большой шестерни может отключить одну из двух веток.",
	"workshop_back":"Зеркальце за рамой показывает: левая ветка возвращает снимок в начало, правая ведёт к внешнему краю.",
	"workshop_belt":"Жорик потянул свободную нитку и вытащил ремень из ниши. Ремень не должен ни провисать, ни пережимать ось.",
	"workshop_loop":"В возвратной ветке свет снова оказывается в начале. Холостой сектор разрывает именно эту связь.",
	"workshop_ledger":"Запись Тадео: «Кармен просила, чтобы последнее окно всегда смотрело на первое». На полях — женщина за фотоаппаратом.",
	"frame_fixed":"Рама перестала возвращать каждый вид в начало. В ней видна дорога, но её нужно связать с настоящей картой.",
	"route_map":"На обычной карте дворик расположен ниже гор. Ласточка смотрит по диагонали вправо, к морской гавани.",
	"route_anchor":"Начало пути должно совпадать с настоящим порогом Кармен, а свободный конец — смотреть к морю.",
	"route_open":"Свет вышел за край рамы. Настоящая улица продолжилась к гавани; путь обратно остаётся открыт.",
	"harbor_arrival":"Семья дошла до настоящей гавани. Архив вернул направление, а поездку им предстоит совершить самим.",
	"harbor_net":"У катамарана чёрная сетка между двумя корпусами. Нико уже выбрал место, откуда лучше всего видно воду.",
	"harbor_icecream":"После кораблика — мороженое в старой Марбелье. На листке Лусия нарисовала два рожка рядом."}

func _ready()->void:
	z_index=-10
	if world.scene_id=="workshop":
		world.lucia.position=Vector2(300,585);world.cat.position=Vector2(414,586)
		world.hotspots.assign([
			{"id":"street","name":"На улицу","rect":Rect2(35,150,291,380),"foot":Vector2(285,583)},
			{"id":"spool","name":"Катушки перед нишей","rect":Rect2(391,405,86,84),"foot":Vector2(490,585)},
			{"id":"drive","name":"Шкивы ременной передачи","rect":Rect2(556,267,85,90),"foot":Vector2(550,586)},
			{"id":"tension","name":"Натяжитель ремня","rect":Rect2(635,294,47,59),"foot":Vector2(643,600)},
			{"id":"sector","name":"Шестерня с холостым сектором · повернуть","rect":Rect2(690,195,112,116),"foot":Vector2(693,600)},
			{"id":"back","name":"Зеркальце за рамой","rect":Rect2(872,168,49,118),"foot":Vector2(889,584)},
			{"id":"link","name":"Трубка от фонтана","rect":Rect2(848,323,81,95),"foot":Vector2(877,602)},
			{"id":"crank","name":"Провернуть ручку","rect":Rect2(526,330,83,84),"foot":Vector2(520,600)},
			{"id":"ledger","name":"Записи Тадео","rect":Rect2(980,348,164,70),"foot":Vector2(1060,585)},
			{"id":"frame_take","name":"Дорожная рамка","rect":Rect2(746,371,160,46),"foot":Vector2(753,600)}])
	elif world.scene_id=="passage" and game.chapter.frame_fixed:
		route_visible=game.chapter.frame_placed
		world.hotspots.insert(0,{"id":"route_table","name":"Карта на столе · дорожная рамка","rect":Rect2(901,363,228,166),"foot":Vector2(832,609)})
	elif world.scene_id=="harbor":
		world.lucia.position=Vector2(354,590);world.cat.position=Vector2(472,600)
		world.hotspots.assign([
			{"id":"courtyard","name":"Вернуться к Кармен","rect":Rect2(25,170,205,348),"foot":Vector2(240,581)},
			{"id":"boat_view","name":"Катамаран у причала","rect":Rect2(390,239,400,266),"foot":Vector2(628,594)},
			{"id":"rope","name":"Канат на тумбе","rect":Rect2(842,416,153,104),"foot":Vector2(910,604)},
			{"id":"icecream","name":"Мороженое после моря","rect":Rect2(1050,240,213,278),"foot":Vector2(1040,602)}])

func stop()->void:dragging=false
func _process(delta:float)->void:
	clock+=delta
	z_index=100 if world.scene_id=="passage" and route_visible else -10
	queue_redraw()

func tooltip(p:Vector2)->String:
	if world.scene_id=="workshop" and back_view and Rect2(334,110,248,203).has_point(p):return "Обратная сторона · нажми, чтобы закрыть"
	if world.scene_id=="passage" and route_visible:
		if Rect2(1020,211,30,30).has_point(p):return "Закрыть крупный вид карты"
		if p.distance_to(Vector2(753,454))<32:return "Порог Кармен · начало настоящей дороги"
		if p.distance_to(Vector2(718,256))<32:return "Озеро · другой берег"
		if Rect2(763,341,150,80).has_point(p):return "Внешняя стрелка · перетащи к гавани"
		if Rect2(665,346,61,64).has_point(p):return "Возвратная защёлка · открыть / закрыть"
		if Rect2(941,432,100,38).has_point(p):return "Закрепить путь"
		if Rect2(656,205,401,290).has_point(p):return "Обычная карта деревни"
	return ""

func input(event:InputEvent)->bool:
	if world.scene_id=="workshop" and back_view and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and Rect2(334,110,248,203).has_point(event.position):back_view=false;return true
	if world.scene_id!="passage" or not route_visible:return false
	if event is InputEventMouseMotion and dragging:
		game.chapter.aim_route((event.position-MAP_CENTER).angle());return true
	if not event is InputEventMouseButton or event.button_index!=MOUSE_BUTTON_LEFT:return false
	if not event.pressed:
		if dragging:dragging=false;game._save_game();return true
		return false
	var p:Vector2=event.position
	if Rect2(1020,211,30,30).has_point(p):route_visible=false;return true
	if p.distance_to(Vector2(753,454))<32:
		if not game.chapter.route_open:game.chapter.route_anchor="courtyard"
		game._note("route_anchor");game.message="Начало закреплено на пороге Кармен.";game._save_game();return true
	if p.distance_to(Vector2(718,256))<32:
		if not game.chapter.route_open:game.chapter.route_anchor="lake"
		game.message="Здесь озеро. Порог Кармен находится в другом месте карты.";game._save_game();return true
	if Rect2(665,346,61,64).has_point(p):
		if not game.chapter.route_open:game.chapter.route_loop=not game.chapter.route_loop
		game.message="Защёлка замкнула свет обратно к началу." if game.chapter.route_loop else "Возврат открыт. Стрелка может вывести свет за край."
		game._save_game();return true
	if Rect2(763,341,150,80).has_point(p) and not game.chapter.route_open:dragging=true;return true
	if Rect2(941,432,100,38).has_point(p):_route_test();return true
	if Rect2(656,205,401,290).has_point(p):return true
	return false

func act(id:String)->bool:
	var s=game.chapter
	match id:
		"spool":
			if s.belt_taken:game.message="Ремень уже найден. Жорик убедился, что ниша пуста."
			else:
				s.spool_moved=true;world.stop();game.transitioning=true;game.scene_kind="cat_belt"
				game.cutscene.start([[0,"cat_thread"],[1.0,"cat_niche"],[2.3,"cat_belt"]],3.2)
		"drive":
			game._note("workshop_mechanism")
			if s.belt_installed:game.message="Ремень на шкивах. Натяжитель справа меняет, как он цепляется за ось."
			elif game.selected_item=="belt" and s.belt_taken:s.belt_installed=true;game.selected_item="";world.lucia.react("pickup");game.message="Ремень наделся на шкивы, но провисает."
			else:game.message="От ручки к шестерне не передаётся движение: на шкивах нет ремня. В нише виден его край."
		"tension":
			s.tighten_belt();game.message="Сначала надень ремень на шкивы." if not s.belt_installed else ["Ремень провисает и скользит.","Ремень натянут ровно. Ось вращается свободно.","Ремень пережал ось. Ручка упирается."][s.belt_tension];game.audio.play("pickup")
		"sector":s.turn_sector();game._note("workshop_mechanism");game.audio.play("pickup");game.message="Пустой сектор поворачивается вместе с шестернёй. В этой стороне движение не передаётся."
		"back":s.back_seen=true;back_view=not back_view;game._note("workshop_back");game.message="Слева передача возвращает вид к началу. Правая ветка ведёт за край рамы."
		"link":
			if not s.echo_fixed:game.message="Трубка тянется от площади, но дальний отклик ещё не вернулся."
			else:s.workshop_linked=true;game.message="Трубка соединилась с рамою. Последняя фраза фонтана теперь доходит сюда.";game.audio.play("box")
		"crank":world.stop();game.transitioning=true;game.scene_kind="frame_trial";game.cutscene.start([[0,"frame_trial"],[2.0,"frame_result"]],3.8)
		"ledger":game._note("workshop_ledger");game.message="Тадео ушёл к причалу. В журнале: «Кармен просила повернуть последнее окно к первому»."
		"frame_take":
			if not s.frame_fixed:game.message="Рамка ещё прикреплена к передаче. Сначала верни ей обратный ход."
			elif s.frame_taken:game.message="Рамка уже с Лусией. На столе лоджии есть обычная карта деревни."
			else:s.frame_taken=true;game.message="Дорожная рамка в сумке. Сравним её с настоящей картой в лоджии.";game.audio.play("pickup");world.lucia.react("pickup")
		"route_table":
			if not s.frame_fixed:return false
			if s.frame_taken and (game.selected_item=="frame" or s.frame_placed):s.frame_placed=true;route_visible=true;game.selected_item="";game._note("route_map");game.message="Карта сохраняет местность. Рама показывает, куда можно выйти. Свяжем их."
			else:game.message="На столе карта. Отремонтированная рамка осталась в мастерской — её можно взять."
		"boat_view":game._note("harbor_net");game.message="Нико: «На сетке будто висишь над водой. Сядем рядом?» Кораблик к Марбелье ждёт у причала."
		"rope":game.message="Канат крепко держит кораблик у берега. Лусия узнаёт ту же непрерывную линию, что помогала в архиве."
		"icecream":game._note("harbor_icecream");world.lucia.react("happy");game.message="Кармен: «Сначала море. А в старом городе — мороженое у фонтана». Лусия рисует два рожка."
		_:return false
	world.sync();game._save_game();return true

func _route_test()->void:
	var s=game.chapter
	if s.route_open:game.message="Дорога уже закреплена. Кармен ждёт на кухне — пора собираться к морю.";return
	if s.try_route():game.audio.play("discovery");game.message="Свет ушёл за край. Настоящая дорога продолжается к морю. Расскажем Кармен на кухне.";game._note("route_open")
	elif s.route_anchor!="courtyard":game.message="Начало не совпадает с настоящим порогом. На карте дворик — внизу, под деревом."
	elif s.route_loop:game.message="Защёлка возвращает свет к первому кадру. Дорога снова замкнулась."
	else:game.message="Стрелка смотрит мимо гавани. Ласточка у моря показывает направление."
	game._save_game()

func beat(id:String)->void:
	var s=game.chapter
	match id:
		"cat_thread":world.lucia.react("pickup");game.message="Катушки отодвинулись. Из ниши торчит свободная нитка; Жорик заметил её."
		"cat_niche":
			world.cat.react("inspect");var t:=create_tween();t.tween_property(world.cat,"position",Vector2(443,504),.55)
		"cat_belt":
			s.belt_taken=true;game._note("workshop_belt");game.message="За ниткой вытянулся старый ремень. Жорик явно считает его своей добычей."
			var t:=create_tween();t.tween_property(world.cat,"position",Vector2(456,586),.55)
		"frame_trial":testing=true;game.audio.play("box");game.message="Следи, где оборот прекращается и куда возвращается свет."
		"frame_result":
			testing=false
			if s.try_frame():game.audio.play("discovery");game._note("frame_fixed");game.message="Свет перестал возвращаться. Между двумя берегами появилась дорога. Рамку можно взять."
			elif not s.belt_installed:game.message="Ручка вращается отдельно: шкивы пока не связаны ремнём."
			elif s.belt_tension==0:game.message="Ремень проскользнул. Оборот не дошёл до большой шестерни."
			elif s.belt_tension==2:game.message="Ось зажата натяжением. Ослабь ремень на один шаг."
			elif not s.back_seen:game.message="На лицевой стороне всё движется, но куда идёт обратная передача? Загляни в зеркальце."
			elif not s.workshop_linked:game.message="Рама ждёт отклика из трубки. Проверь её соединение с фонтаном."
			elif s.idle_sector!=4:game._note("workshop_loop");game.message="Левая ветка вернула свет в начало. Поверни пустой сектор к возвратной шестерне."
			else:game.message="Вторая связь ещё не закрепилась. Вернись к фонтану на площади."
	game._save_game()

func _draw()->void:
	if game==null:return
	if world.scene_id=="workshop":_workshop()
	elif world.scene_id=="passage" and route_visible:_map()

func _gear(at:Vector2,radius:float,gap:float=-10,spin:float=0)->void:
	var pts:=PackedVector2Array()
	for i:int in 80:
		var a:float=TAU*i/80.0+spin
		var dist:float=radius if i%4 in [1,2] else radius-5
		if absf(wrapf(a-gap,-PI,PI))<.36 and gap>-9:dist=radius-13
		pts.append(at+Vector2.from_angle(a)*dist)
	draw_colored_polygon(pts,Color("bc9a5c"));draw_polyline(pts+PackedVector2Array([pts[0]]),Color("695334"),2,true)
	draw_circle(at,radius*.52,Color("6b624d"));draw_circle(at,radius*.44,Color("977e50"));draw_circle(at,6,Color("e1c78f"))
	for i:int in 4:
		var v:=Vector2.from_angle(i*PI*.5+spin)*radius*.34;draw_line(at,at+v,Color("685536"),3,true)

func _workshop()->void:
	var s=game.chapter;var spin:float=clock*2 if testing and s.belt_installed and s.belt_tension==1 else 0
	draw_line(DRIVE,GEAR,Color("443f32"),7,true);draw_line(GEAR,LOOP,Color("9b7c47"),6,true);draw_line(GEAR,OUT,Color("9b7c47"),6,true)
	_gear(DRIVE,25,-10,spin);_gear(LOOP,28,-10,-spin if s.idle_sector!=4 else 0);_gear(OUT,22,-10,-spin if s.idle_sector!=7 else 0)
	_gear(GEAR,54,s.idle_sector*PI/4,0)
	var gap:Vector2=GEAR+Vector2.from_angle(s.idle_sector*PI/4)*49
	draw_arc(GEAR,45,s.idle_sector*PI/4-.30,s.idle_sector*PI/4+.30,15,Color("e5d6a2"),3,true)
	draw_circle(gap,4,Color("f4e0ac"))
	if s.belt_installed:
		var dip:float=17 if s.belt_tension==0 else 0
		draw_polyline(PackedVector2Array([DRIVE+Vector2(-15,-19),Vector2(652,300+dip),GEAR+Vector2(-24,41)]),Color("3c3028"),6,true)
		draw_polyline(PackedVector2Array([DRIVE+Vector2(15,19),Vector2(681,342+dip),GEAR+Vector2(24,41)]),Color("3c3028"),6,true)
	draw_circle(Vector2(658,320),14,Color("ae8a50"));draw_line(Vector2(648,328),Vector2(666,309+5*s.belt_tension),Color("e3c083"),4,true)
	draw_line(DRIVE,Vector2(564,361),Color("9d7a46"),6,true);draw_circle(Vector2(559,368),10,Color("533c2b"))
	draw_arc(Vector2(905,205),19,0,TAU,40,Color("ba9555"),3,true);draw_circle(Vector2(905,205),16,Color("b8c8b7"))
	draw_polyline(PackedVector2Array([OUT,Vector2(871,246),Vector2(876,350)]),Color("b29665"),4,true)
	draw_line(Vector2(876,350),Vector2(898,389),Color("746343"),5,true)
	draw_circle(Vector2(876,350),7,Color("9ac0bd") if s.workshop_linked else Color("53493a"))
	if s.workshop_linked:
		for i:int in 3:draw_arc(Vector2(876,352),10+i*6+sin(clock*3)*2,0,TAU,30,Color(.67,.85,.80,.35),1,true)
	if not s.belt_taken:draw_line(Vector2(443,439),Vector2(495,492),Color("ddcdb0"),2,true)
	if s.spool_moved:draw_circle(Vector2(488,473),10,Color("d3b27b"))
	if s.frame_fixed:
		draw_line(GEAR,OUT,Color("d8e9b2"),3,true)
		if not s.frame_taken:
			draw_style_box(game.ui.style(Color("bea473")),Rect2(760,379,116,26));draw_rect(Rect2(767,384,102,15),Color("60958e"));draw_line(Vector2(775,395),Vector2(859,389),Color("f7eacb"),2,true)
	if testing and s.belt_installed and s.belt_tension==1:
		var target:Vector2=OUT if s.idle_sector==4 else LOOP
		var f:float=fmod(clock*.8,1);draw_circle(GEAR.lerp(target,f),5,Color("f5edb7"))
	if back_view:
		draw_style_box(game.ui.style(Color("f5e7c7")),Rect2(334,110,248,203))
		draw_string(font,Vector2(348,139),"Обратная сторона  ×",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("354250"))
		draw_arc(Vector2(399,215),34,0,TAU,40,Color("977447"),4,true)
		draw_line(Vector2(431,215),Vector2(540,170),Color("698d87"),4,true)
		draw_string(font,Vector2(350,278),"↺ к началу     → наружу",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("354250"))
		draw_line(Vector2(534,170),Vector2(542,170),Color("698d87"),3,true)

func _map()->void:
	var s=game.chapter
	draw_style_box(game.ui.style(Color("f2e2bf")),Rect2(656,205,401,290))
	draw_string(font,Vector2(675,232),"Карта на столе",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("354250"))
	draw_string(font,Vector2(1028,233),"×",HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("354250"))
	var points:=PackedVector2Array([Vector2(753,454),Vector2(780,413),MAP_CENTER,Vector2(883,332),Vector2(997,251)])
	draw_polyline(points,Color("cfb98f"),20,true);draw_polyline(points,Color("e9d5ae"),15,true)
	draw_arc(Vector2(718,256),22,0,TAU,40,Color("6faaa9"),4,true)
	draw_colored_polygon(PackedVector2Array([Vector2(697,270),Vector2(718,244),Vector2(739,270)]),Color("81aaa2"))
	draw_rect(Rect2(737,436,32,27),Color("ae7c52"));draw_colored_polygon(PackedVector2Array([Vector2(731,438),Vector2(753,418),Vector2(775,438)]),Color("af6750"))
	draw_string(font,Vector2(755,485),"Дворик",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("354250"))
	draw_string(font,Vector2(682,295),"Озеро",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("354250"))
	for i:int in 3:draw_line(Vector2(957,259+i*9),Vector2(1032,259+i*9),Color("70a6a5"),3,true)
	draw_string(font,Vector2(947,312),"Гавань",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("354250"))
	draw_polyline(PackedVector2Array([Vector2(990,244),Vector2(997,251),Vector2(1004,238)]),Color("3f7680"),3,true)
	var anchor:Vector2=Vector2(753,454) if s.route_anchor=="courtyard" else Vector2(718,256)
	if s.route_anchor!="none":draw_line(anchor,MAP_CENTER,Color("9d9b66"),3,true);draw_circle(anchor,7,Color("426f73"))
	draw_circle(MAP_CENTER,11,Color("b99b59"))
	var end:Vector2=MAP_CENTER+Vector2.from_angle(s.route_angle)*119
	draw_line(MAP_CENTER,end,Color("427a7f"),6,true)
	var head:=Vector2.from_angle(s.route_angle)
	draw_colored_polygon(PackedVector2Array([end+head*13,end-head*4+head.orthogonal()*9,end-head*4-head.orthogonal()*9]),Color("427a7f"))
	draw_arc(Vector2(695,378),20,0,TAU*.86 if s.route_loop else PI*.8,32,Color("b99660"),5,true)
	if s.route_loop:draw_line(Vector2(709,361),Vector2(710,391),Color("674e33"),4,true)
	draw_style_box(game.ui.style(Color("e6d2a4")),Rect2(941,432,100,38));draw_string(font,Vector2(951,456),"Закрепить",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("354250"))
	if s.route_open:draw_polyline(points,Color("f8f2c3"),3,true);draw_circle(Vector2(997,251),7,Color("f8f2c3"))
