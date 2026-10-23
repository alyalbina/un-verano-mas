extends Node2D
## In-world mechanisms. State owns every durable result; this node owns feedback.
var world:Node2D
var game:Node
var clock:=0.0
var music_elapsed:=-1.0
var music_active:=false
var inspection_open:=false
var dragging:=false
var last_mouse:=Vector2.ZERO
var font:=ThemeDB.fallback_font
const MIRROR_CENTER=Vector2(621,272)
const VALVES=[Vector2(490,438),Vector2(660,438),Vector2(825,438)]
const ROUTES=[
	[Vector2(658,309),Vector2(658,386),Vector2(490,386),Vector2(490,438),Vector2(431,438),Vector2(431,357)],
	[Vector2(658,309),Vector2(660,438),Vector2(905,438),Vector2(985,450),Vector2(985,413)],
	[Vector2(658,309),Vector2(658,459),Vector2(825,459),Vector2(825,438),Vector2(825,354),Vector2(739,350)]]

func _ready()->void:
	z_index=-15
	if world.scene_id=="street":
		world.hotspots.assign([
			{"id":"passage","name":"К скрытой лоджии","rect":Rect2(25,202,163,325),"foot":Vector2(189,583)},
			{"id":"jug","name":"Керамический кувшин","rect":Rect2(285,318,80,90),"foot":Vector2(332,583)},
			{"id":"faucet","name":"Кран над водостоком","rect":Rect2(492,303,67,82),"foot":Vector2(433,590)},
			{"id":"drain","name":"Слив и рычаг противовеса","rect":Rect2(681,382,77,109),"foot":Vector2(761,583)},
			{"id":"mount","name":"Крепление под навесом","rect":Rect2(580,223,83,97),"foot":Vector2(568,579)},
			{"id":"reflection","name":"Табличка в воде","rect":Rect2(390,417,300,71),"foot":Vector2(508,591)},
			{"id":"arch","name":"Скол у арки мастерской","rect":Rect2(781,151,259,371),"foot":Vector2(1049,585)},
			{"id":"street_sign","name":"Табличка без последней строки","rect":Rect2(997,65,92,73),"foot":Vector2(824,590)},
			{"id":"plaza","name":"На площадь","rect":Rect2(1146,239,129,287),"foot":Vector2(1114,582)}])
	else:
		world.hotspots.assign([
			{"id":"street","name":"На улицу","rect":Rect2(28,195,189,332),"foot":Vector2(233,583)},
			{"id":"cup","name":"Верхняя чаша фонтана","rect":Rect2(603,280,113,78),"foot":Vector2(618,602)},
			{"id":"valve_0","name":"Короткий слив","rect":Rect2(464,412,54,54),"foot":Vector2(460,601)},
			{"id":"valve_1","name":"Трубка к дальнему сливу","rect":Rect2(634,412,54,54),"foot":Vector2(635,602)},
			{"id":"valve_2","name":"Обратная петля","rect":Rect2(799,412,54,54),"foot":Vector2(805,602)},
			{"id":"musician","name":"Послушать гитариста","rect":Rect2(1058,276,165,270),"foot":Vector2(984,607)},
			{"id":"routes","name":"Трубки и известковый след","rect":Rect2(873,383,169,80),"foot":Vector2(902,607)},
			{"id":"olives","name":"Столик под деревом","rect":Rect2(1194,380,81,130),"foot":Vector2(1127,608)}])
	world.cat.position=Vector2(350,588) if world.scene_id=="street" else Vector2(331,598)

func _process(delta:float)->void:
	clock+=delta
	if music_active:music_elapsed+=delta
	queue_redraw()

func tooltip(p:Vector2)->String:
	if inspection_open and Rect2(209,121,358,195).has_point(p):return "У бортика · нажми, чтобы закрыть крупный вид"
	if world.scene_id=="street" and game.chapter.mirror_mounted and Rect2(580,223,83,97).has_point(p) and not game.chapter.street_open:
		return "Повернуть зеркало · перетащи влево или вправо"
	return ""

func input(event:InputEvent)->bool:
	if world.scene_id!="street":return false
	if event is InputEventMouseMotion and dragging:
		game.chapter.turn_mirror(game.chapter.reflection_angle+(event.position.x-last_mouse.x)*.008)
		last_mouse=event.position;game.message="Зеркало меняет угол. Скол в отражении движется относительно каменного края.";return true
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if not event.pressed and dragging:
			dragging=false;game._save_game();return true
		if event.pressed and inspection_open and Rect2(209,121,358,195).has_point(event.position):inspection_open=false;return true
		if event.pressed and game.chapter.mirror_mounted and not game.chapter.street_open and Rect2(580,223,83,97).has_point(event.position):
			dragging=true;last_mouse=event.position;world.path.clear();world.pending="";return true
	return false

func stop()->void:dragging=false

func act(id:String)->void:
	var s=game.chapter
	match id:
		"jug":
			if s.jug:game.message="Кувшин уже у Лусии. Вода делает его подходящим противовесом."
			else:s.jug=true;world.lucia.react("pickup");game.audio.play("pickup");game.message="Тяжёлый керамический кувшин. На ручке след от старого рычага."
		"faucet":
			if game.selected_item=="jug" and s.jug and not s.drain_held:
				s.jug_filled=true;s.water_on=true;game.selected_item="";world.lucia.react("pickup");game.message="Кувшин наполнился. Пока слив открыт, вода в чаше не задерживается."
			else:
				s.water_on=not s.water_on;game.message="Кран открыт. Вода течёт к сливу." if s.water_on else "Кран закрыт. Поверхность снова опустела."
			game._note("water_flow")
		"drain":
			if s.drain_held:
				s.hold_drain();game.message="Кувшин снова в сумке. Слив открылся; отражение распалось.";game.selected_item=""
			elif game.selected_item!="jug":game.message="У рычага есть петля для ручки кувшина. Без противовеса он возвращается вниз."
			elif not s.jug_filled:game.message="Пустой кувшин слишком лёгкий: рычаг всё ещё открывает слив."
			else:
				s.hold_drain();game.selected_item="";world.lucia.react("pickup")
				game.message="Вес кувшина удержал слив. Вода стала спокойной." if s.water_on else "Противовес держится. Теперь чашу нужно наполнить."
				if s.water_on:
					var t:=world.create_tween();t.tween_property(world.cat,"position",Vector2(695,450),.7).set_trans(Tween.TRANS_QUAD);t.tween_interval(.9);t.tween_property(world.cat,"position",Vector2(760,586),.6)
		"mount":
			if s.mirror_mounted and s.street_open:
				s.mirror_mounted=false;game.message="Зеркало снова в сумке. Улица уже удержала проход; он не исчезнет."
			elif s.mirror_mounted:game.message="Зеркало на шарнире. Меняй его угол и наблюдай скол в воде."
			elif game.selected_item=="mirror" and s.mirror:
				s.mirror_mounted=true;game.selected_item="";game._note("mirror_mount");world.lucia.react("pickup");game.message="Зеркало закрепилось под навесом. Теперь видны обе стороны арки."
			else:game.message="Пустое круглое крепление. Подойдёт карманное зеркало Кармен."
		"reflection":
			inspection_open=true;game._note("street_sign")
			if not s.still_water():game.message="В потоке табличка дробится. Отражение должно оставаться на одном месте."
			elif not s.mirror_mounted:game._note("still_water");game.message="Табличка читается, но вода смотрит только вверх. Нужно закрепить зеркало под навесом."
			else:s.seen_reflection=true;game._note("still_water");game.message="В неподвижной воде строка длиннее. Под ней отражён скол на другой стороне арки."
		"street_sign":game._note("street_sign");game.message="CALLE DEL AGUA. В отражении после этой строки остаётся ещё одно слово."
		"arch":
			s.seen_arch=true;game._note("arch_chip")
			if s.street_open and s.can_enter("workshop"):game.change_scene("workshop")
			elif s.street_open:game.message="За аркой — мастерская. В её раме не хватает ответа из фонтана." if not s.echo_fixed else "Мастерская ответила. Но рама внутри ещё требует обратного хода."
			elif s.try_reflection():
				game.scene_kind="street_open";game.transitioning=true;world.stop();game.cutscene.start([[0,"street_unfold"],[1.5,"street_word"]],3.3)
			elif not s.still_water():game.message="Скол настоящий, но его отражение уносит поток воды."
			elif not s.mirror_mounted:game.message="В воде видно только небо. Нужно связать два вида арки."
			elif not s.seen_reflection:game.message="Отсюда видна только одна сторона. Загляни в воду у бортика."
			else:game.message="Скол и его отражение ещё расходятся. Поверни зеркало под навесом."
		"cup":
			if s.cup_filled:game.message="Чаша наполнена. Три трубки делят один поток воды."
			elif game.selected_item=="jug" and s.jug_filled and not s.drain_held:
				s.cup_filled=true;game.selected_item="";game._note("fountain_routes");world.lucia.react("pickup");game.message="Чаша наполнилась. В кувшине осталось достаточно воды для противовеса."
			else:game.message="Сухая чаша связана с тремя трубками. Для опыта нужна вода из кувшина."
		"valve_0","valve_1","valve_2":
			var i:int=int(id.right(1));s.toggle_valve(i);game._note("fountain_routes")
			game.message=["Короткая ветка","Длинная трубка к дальнему сливу","Возвратная петля"][i]+(" открыта." if s.valves[i] else " закрыта.")+" Видимый поток показывает её путь."
			game.audio.play("pickup")
		"routes":game._note("fountain_routes");game.message="Белый след ведёт к дальнему сливу. Обходные трубки возвращают воду прямо в чашу."
		"musician":
			game._note("guitar");game.scene_kind="music";game.transitioning=true;world.stop()
			game.cutscene.start([[0,"music_start"],[.7,"music_middle"],[2.1,"music_far"],[3.6,"music_result"]],4.5)
		"olives":game._note("olives");world.lucia.react("happy");game.message="Оливки, прохладная вода и тень апельсинового дерева. Можно задержаться и послушать музыку."
	world.sync();game._save_game()

func beat(id:String)->void:
	var s=game.chapter
	match id:
		"street_unfold":game.audio.play("discovery");world.lucia.react("inspect");game.message="Сколы совпали. За аркой появилась глубина, которой раньше не было."
		"street_word":game.message="Вторая строка таблички: TALLER. Отражение сохранило путь к мастерской."
		"music_start":
			music_active=true;music_elapsed=0;s.heard_motif=true;game._note("motif");game.audio.play("guitar_motif")
			game.message="Три фразы. Ленты у воды отвечают на них в разное время."
		"music_far":game.message="Последняя фраза ждёт ответа у дальнего слива."
		"music_result":
			music_active=false
			if s.try_echo():game.audio.play("discovery");game.message="Ответ прошёл по длинной трубке. Фонтан ожил, в мастерской отозвалась латунная рама."
			elif not s.cup_filled:game.message="Чаша сухая. Музыка не проходит через пустые трубки."
			elif s.valves.count(true)>1:game.message="Два потока накладываются. Ленты отвечают сразу; последний отклик гаснет."
			elif s.valves==[true,false,false]:game.message="Короткий слив отвечает слишком рано — ещё до последней фразы."
			elif s.valves==[false,false,true]:game.message="Поток вернулся в чашу. На дальнем конце никто не ответил."
			else:game.message="Все ветки закрыты. У воды нет пути к дальнему сливу."
	game._save_game()

func _jug(center:Vector2,scale_value:float=1)->void:
	draw_set_transform(center,0,Vector2.ONE*scale_value)
	draw_circle(Vector2(7,-19),15,Color("3a617b"));draw_circle(Vector2(7,-19),9,Color("f5dfb9"))
	draw_colored_polygon(PackedVector2Array([Vector2(-21,0),Vector2(-25,-35),Vector2(-12,-49),Vector2(-12,-61),Vector2(9,-61),Vector2(10,-47),Vector2(18,-35),Vector2(17,0)]),Color("ece1bd"))
	for y:int in [-9,-26,-37]:draw_line(Vector2(-18,y),Vector2(13,y),Color("386b9c"),3,true)
	draw_circle(Vector2(-4,-19),5,Color("386b9c"));draw_set_transform(Vector2.ZERO)

func _poly(points:Array,ink:Color,width:float)->void:
	draw_polyline(PackedVector2Array(points),ink,width,true)

func _draw()->void:
	if game==null:return
	var s=game.chapter
	if world.scene_id=="street":_street(s)
	else:_plaza(s)

func _street(s:RefCounted)->void:
	# Chipped azulejo corner is visible from the arch viewpoint too.
	draw_colored_polygon(PackedVector2Array([Vector2(784,379),Vector2(795,379),Vector2(784,390)]),Color("eee0bd"))
	var basin:=Rect2(405,430,285,15)
	if s.water_on:draw_rect(basin,Color("688a86"))
	if s.water_on:
		draw_line(Vector2(522,365),Vector2(522,433),Color(.75,.92,.91,.68),3,true)
		if not s.drain_held:
			for i:int in 6:
				var x:=413+fmod(clock*73+i*43,261);draw_line(Vector2(x,437),Vector2(x+13,438),Color(.90,.96,.86,.7),2,true)
		else:
			draw_line(Vector2(413,432),Vector2(682,432),Color("d2e4d1"),2,true)
			var delta_x:float=clampf((s.reflection_angle-.28)*105,-95,95)
			# The stationary lip is evidence; only the reflected matching chip moves.
			var fixed:=PackedVector2Array([Vector2(578,430),Vector2(582,424),Vector2(588,430)])
			draw_colored_polygon(fixed,Color("efe6cf"))
			if s.mirror_mounted:
				var reflected:=PackedVector2Array([Vector2(578+delta_x,434),Vector2(582+delta_x,440),Vector2(588+delta_x,434)])
				draw_colored_polygon(reflected,Color("d5dbc0"))
				# A real section of the arch, inverted and compressed into water.
				draw_line(Vector2(581+delta_x,436),Vector2(581+delta_x,445),Color(.27,.42,.52,.8),4,true)
				var col:=Color("263b4b");draw_string(font,Vector2(426,445),"AGUA  /  TALLER" if s.street_open else "AGUA  /  …",HORIZONTAL_ALIGNMENT_LEFT,-1,10,col)
	var lever:=Vector2(710,407)
	draw_line(lever-Vector2(18,0),lever+Vector2(25,-19 if s.drain_held else 13),Color("947545"),6,true)
	draw_circle(lever,7,Color("bfa46a"))
	if s.drain_held:_jug(Vector2(728,443),.65)
	elif not s.jug:_jug(Vector2(325,379),.86)
	draw_arc(MIRROR_CENTER,31,0,TAU,48,Color("947545"),4,true)
	if s.mirror_mounted:
		draw_circle(MIRROR_CENTER,27,Color("bacbc7"));draw_arc(MIRROR_CENTER,25,0,TAU,48,Color("d6b874"),3,true)
		var v:=Vector2(20,0).rotated(s.reflection_angle)
		draw_line(MIRROR_CENTER-v,MIRROR_CENTER+v,Color("f7f0d7"),4,true)
		draw_circle(MIRROR_CENTER+v,5,Color("936e43"))
	if s.street_open:
		draw_string(font,Vector2(1007,116),"TALLER",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("38536a"))
		_poly([Vector2(1016,521),Vector2(869,572),Vector2(645,607)],Color(.30,.40,.35,.24),20)
	if inspection_open:_reflection_detail(s)
	if s.echo_fixed and s.street_open:
		for i:int in 3:draw_arc(Vector2(910,397),20+i*15+sin(clock*2)*2,-1.5,1.5,36,Color(.91,.75,.44,.4),2,true)

func _plaza(s:RefCounted)->void:
	for i:int in 3:
		_poly(ROUTES[i],Color("67513b"),9);_poly(ROUTES[i],Color("b18b51"),6)
		var highlight:Array=[]
		for point:Vector2 in ROUTES[i]:highlight.append(point-Vector2(1,1))
		_poly(highlight,Color(.91,.75,.45,.66),1.2)
		if s.cup_filled and s.valves[i]:
			_poly(ROUTES[i],Color(.44,.74,.77,.7),3)
			var pts:=PackedVector2Array(ROUTES[i]);var travel:float=fmod(clock*.35,1.0);var lengths:Array[float]=[];var total:=0.0
			for j:int in range(pts.size()-1):var d:float=pts[j].distance_to(pts[j+1]);lengths.append(d);total+=d
			var at:=travel*total
			for j:int in lengths.size():
				if at<=lengths[j]:draw_circle(pts[j].lerp(pts[j+1],at/lengths[j]),4,Color("dce8cc"));break
				at-=lengths[j]
		var c:Vector2=VALVES[i];draw_circle(c+Vector2(1,2),20,Color(.2,.15,.09,.22));draw_circle(c,18,Color("715638"));draw_circle(c,14,Color("b59458"))
		draw_arc(c-Vector2(1,1),16,3.35,5.8,24,Color("dcc389"),2,true)
		for j:int in 5:draw_line(c+Vector2(-10+j*4,-9),c+Vector2(-10+j*4,-3),Color(.44,.34,.21,.14),1,true)
		var a:=0.0 if s.valves[i] else PI*.5
		var axis:=Vector2(14,0).rotated(a);draw_line(c-axis,c+axis,Color("674f33"),5,true);draw_circle(c,4,Color("dfc78a"))
	if s.cup_filled:_paint_ellipse(Vector2(658,307),Vector2(40,8),Color(.25,.58,.66,.85))
	var positions:=[Vector2(431,329),Vector2(739,323),Vector2(985,387)]
	for i:int in 3:
		var p:Vector2=positions[i];var wave:=0.0
		draw_line(p+Vector2(6,0),p+Vector2(6,-17),Color("987340"),3,true)
		if music_active:
			var delay:float=[.15,.75,2.25][i]
			var age:float=music_elapsed-delay
			if age>0 and age<1.15:wave=sin(age*7)*13
			var active_branch:bool=s.cup_filled and (s.valves[0] if i==0 else s.valves[2] if i==1 else s.long_route())
			if not active_branch:wave*=.16
		var strip:=PackedVector2Array([p,p+Vector2(12,0),p+Vector2(12+wave,38),p+Vector2(wave,38)])
		draw_colored_polygon(strip,[Color("c66851"),Color("e2b767"),Color("5b93a5")][i])
		if music_active:
			var age:float=music_elapsed-[.15,.75,2.25][i]
			if age>0 and age<1.15:
				var alpha:=.75 if i<2 or s.long_route() else .18
				draw_arc(p+Vector2(6,11),8+age*27,0,TAU,40,Color(.92,.84,.60,alpha*(1-age/1.15)),2,true)
	if s.echo_fixed:
		draw_line(Vector2(658,283),Vector2(658,313),Color(.75,.91,.86,.82),4,true)
		for i:int in 3:draw_arc(Vector2(655,373),15+i*16+sin(clock*2)*2,0,PI,48,Color(.89,.96,.87,.50),2,true)
		for i:int in 2:draw_arc(Vector2(985,427),12+i*13+sin(clock*2)*2,0,TAU,40,Color(.96,.80,.42,.55),2,true)

func _paint_ellipse(center:Vector2,radius:Vector2,ink:Color)->void:
	draw_set_transform(center,0,radius);draw_circle(Vector2.ZERO,1,ink);draw_set_transform(Vector2.ZERO)


func _reflection_detail(s:RefCounted)->void:
	# A close view of the SAME water and chipped lip, not a separate lock screen.
	var r:=Rect2(216,128,344,181)
	draw_style_box(game.ui.style(Color("bda885")),r.grow(7))
	draw_rect(r,Color("385f65"))
	var tex:Texture2D=game.art.street
	draw_set_transform(Vector2(225,293),0,Vector2(1,-.39))
	if s.still_water() and s.mirror_mounted:
		draw_texture_rect_region(tex,Rect2(0,0,321,335),Rect2(1017,180,322,420),Color(1,1,1,.50))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(216,128,344,41),Color("d9caa7"))
	draw_string(font,Vector2(230,153),"У бортика                         ×",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("354250"))
	var x:=388.0
	draw_colored_polygon(PackedVector2Array([Vector2(x-13,169),Vector2(x,181),Vector2(x+13,169)]),Color("466b70"))
	if s.still_water() and s.mirror_mounted:
		var offset:float=clampf((s.reflection_angle-.28)*180,-138,138)
		draw_colored_polygon(PackedVector2Array([Vector2(x-13+offset,188),Vector2(x+offset,176),Vector2(x+13+offset,188)]),Color("ddd3af"))
		draw_line(Vector2(x+offset,193),Vector2(x+offset,275),Color(.8,.87,.76,.66),3,true)
	else:
		for i:int in 8:
			var y:float=184+i*15;var move:float=sin(clock*4+i)*17 if s.water_on else 0.0
			draw_line(Vector2(229+move,y),Vector2(543+move*.5,y+4),Color(.69,.85,.82,.42),3,true)
	draw_string(font,Vector2(241,290),"CALLE DEL AGUA / TALLER" if s.street_open else "CALLE DEL AGUA / …",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("dedac0"))
