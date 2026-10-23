extends Node2D
const Panorama=preload("res://scripts/panorama.gd")
const State=preload("res://scripts/reboot_state.gd")
const World=preload("res://scripts/reboot_world.gd")
const UI=preload("res://scripts/reboot_ui.gd")
const Audio=preload("res://scripts/audio.gd")
const Journey=preload("res://scripts/journey_episode.gd")
const Cutscene=preload("res://scripts/cutscene_controller.gd")
const SAVE="user://photograph_v0_8.json"
const LEGACY_SAVE="user://photograph_v0_7.json"
const TITLES={"courtyard":"Дворик Кармен","kitchen":"Кухня","passage":"Между двумя берегами","street":"Улица отражений","plaza":"Площадь трёх откликов","workshop":"Мастерская обратного хода","harbor":"Гавань · начало поездки"}
const NOTES={"wall":"На белой стене остался каменный порог. Двери нет.","photo":"На снимке есть синяя дверь. Полотенце над ней отсутствует.","sun":"Снимок в прямом солнце отбрасывает тень изображённой двери.","cord":"Шнур заканчивается звоночком. Жорик может добраться через ящик и полку.","mirror":"Движущийся солнечный блик привлекает Жорика; неподвижный быстро надоедает.","cat":"Кот потянул шнур. Тень полотенца больше не разрезает дверь.","threshold":"Тень стала проходом только после соединения с тенью доски.","archive":"На одном снимке — два настоящих берега. Сохранились места, пропал путь между ними.","watermelon":"Кармен обещала арбуз у воды. В этом путешествии можно просто остановиться.","carmen":"Кармен помнит двор иначе. Она не удивилась самой фотографии — только открытой двери.","tile":"Ласточка на старой плитке смотрит в сторону моря.","street_sign":"Табличка CALLE DEL AGUA в воде длиннее, чем на стене.","arch_chip":"Скол азулехо у арки повторяется в отражении. Эти края можно совместить.","still_water":"Тяжёлый кувшин удерживает рычаг. Когда слив закрыт, вода перестаёт дробить отражение.","water_flow":"Кран питает неглубокую чашу; открытый слив не даёт воде задержаться.","mirror_mount":"Шарнир под навесом удерживает зеркало. Его поворот меняет видимую сторону арки.","reflection_join":"Совпавший скол открыл путь к мастерской. Отражение сохранило продолжение улицы.","fountain_routes":"Три трубки делят воду: короткий слив, длинный путь к дальнему сливу и возвратная петля.","motif":"Гитарист играет три фразы. Последняя ждёт более позднего ответа у дальнего слива.","echo_anchor":"Один длинный поток перенёс отклик; фонтан ожил, в мастерской ответила латунная рама.","connection":"Мастерскую удерживают две связи: непрерывное отражение и ответ на другом конце воды. Внутри ещё не восстановлен обратный ход.","guitar":"На площади можно попросить музыканта повторить мотив. Ритм виден по движениям лент даже без звука.","olives":"Под апельсиновым деревом — оливки и прохладная вода. Здесь можно просто посидеть и послушать."}
const HINTS={
"find":["Ящик давно не открывали. Что Кармен могла оставить в нём?","След на стене похож на порог без двери. Сравни его со старым снимком.","Осмотри старый ящик слева во дворе."],
"photo":["У снимка и нынешнего дворика есть два заметных различия.","На полку падает прямое солнце. Лусии трудно удерживать снимок неподвижно.","Положи фотографию на солнечную полку под шнуром."],
"cat":["В тени двери есть светлая полоса. Посмотри выше.","Полотенце держится на шнуре с колокольчиком; до него можно добраться через ящик и полку. Жорик любит движущиеся блики.","Возьми зеркало на кухне. Выбери его в сумке и веди блик: на ящик, на полку, затем к звоночку. Дождись каждого прыжка."],
"align":["Старая кладка хранит очертания порога и косяков.","Горизонтальное движение снимка меняет положение тени, вертикальное — её высоту. Нужны оба совпадения.","Перетащи латунную ручку у снимка вправо примерно на 68 пикселей и вверх на 52. Совмести края тени с двумя следами на стене."],
"bridge":["Тень попала в порог, но обрывается у пола.","Тень поворотной доски может дотянуться до двери. Смотри на её дальний конец.","Поверни доску за правый край: веди его вниз до уровня примерно на 18 пикселей ниже гвоздя. Затем коснись двери."],
"entry":["За стеной слышится вода.","Проход уже открыт и не захлопнется при возвращении.","Нажми на дверь или кнопку «В проход»."],
"archive":["Здесь рядом оказались море и озеро.","На столе лежит снимок с двумя берегами. Что должно быть между ними?","Осмотри два снимка на столе справа."],
"after":["У лоджии появилась обычная улица. Путь продолжается.","На улице и площади сохранились два разных следа одной дороги.","Закрой альбом, нажми «На улицу» в лоджии. Оттуда доступна площадь."],
"water":["Что заставляет отражение дробиться?","Рычаг слива возвращается без противовеса. Пустой кувшин слишком лёгкий.","Возьми кувшин, выбери его в сумке и наполни у крана. Выбери снова и повесь на рычаг слива. Оставь кран открытым."],
"reflection":["Один скол видно с двух сторон. Они сейчас расходятся.","Неподвижная вода удерживает вид, зеркало меняет его угол. Осмотри и воду, и арку.","Выбери зеркало, закрепи под навесом. Осмотри отражение у бортика и арку. Потяни зеркало вправо до совпадения светлых сколов у края воды, затем коснись арки."],
"street_done":["За аркой есть рама, которая ещё не отвечает.","Улица сохранила вид. На площади нужно вернуть другой конец отклика.","Забери кувшин с рычага, если он там. Иди на площадь и исследуй фонтан."],
"music":["Последняя фраза музыки ждёт ответа в другом конце площади.","Две обходные трубки отвечают раньше. Белый след ведёт к дальнему сливу.","Наполни кувшин у крана и налей в верхнюю чашу. Закрой левую и правую ветки, открой среднюю, затем попроси гитариста повторить мотив."],
"echo_done":["Фонтан передал отклик, но вид мастерской ещё нужно удержать.","Спокойная вода на улице может сохранить отражение прохода.","Вернись на улицу, совмести скол в отражении с краем арки и коснись её."],
"connection":["Из открытой арки слышен скрип шестерни.","Две связи удержали мастерскую. Внутри рама возвращает каждый вид к началу.","Нажми на арку мастерской на улице. Осмотри передачу и зеркальце за ней."],
"frame":["Почему свет снова оказывается в начале? Проверь обратную сторону рамы.","Пустой сектор шестерни должен остановить возвратную ветку слева. Натянутый ремень передаёт оборот от ручки.","Отодвинь катушки, выбери найденный ремень и надень на шкивы. Натяжитель нажми один раз от свободного состояния. Загляни в зеркальце, подключи трубку после фонтана, поверни пустой сектор влево и проверь ручку."],
"route":["Рама показывает путь, но где он начинается в настоящем?","Дворик внизу карты — начало. Ласточка справа вверху указывает на гавань. Возвратная защёлка не должна замыкать свет.","Возьми рамку с верстака, выбери в сумке и нажми карту на столе лоджии. Нажми домик внизу, открой защёлку слева, перетащи стрелку к гавани справа вверху и нажми «Закрепить»."],
"departure":["Настоящая улица уже продолжается к морю.","Кармен ждёт на кухне. Ей нужно рассказать об открывшейся дороге.","Вернись на кухню через карту и поговори с Кармен. Затем в дворике нажми «К гавани»."],
"harbor":["Вы дошли до настоящего моря.","У причала ждёт катамаран, а в Марбелье будет мороженое.","Первая глава закончена. Здесь можно осмотреть кораблик и причал, а затем вернуться в деревню. Морская глава ещё в разработке."]}
var chapter=State.new()
var art:Dictionary={}
var world:Node2D
var ui:Control
var audio:Node
var ambient:AudioStreamPlayer
var cutscene:Node
var modal:=""
var transitioning:=false
var selected_item:=""
var selected_kind:=""
var message:="Кармен позвала на кухню. Жорик остался возле старого ящика."
var test_mode:=false
var save_path:=SAVE
var legacy_path:=LEGACY_SAVE
var save_error:=false
var save_blocked:=false
var quitting:=false
var scene_kind:=""
var new_note:=""

func _ready()->void:
	process_mode=Node.PROCESS_MODE_ALWAYS;get_tree().auto_accept_quit=false
	test_mode="--qa" in OS.get_cmdline_user_args();_load_art()
	if not test_mode:_load_game()
	audio=Audio.new();add_child(audio);audio.muted=chapter.muted
	ambient=AudioStreamPlayer.new();ambient.process_mode=Node.PROCESS_MODE_ALWAYS;ambient.volume_db=-25;add_child(ambient)
	cutscene=Cutscene.new();add_child(cutscene);cutscene.beat.connect(_beat);cutscene.finished.connect(_cutscene_finished)
	var canvas:=CanvasLayer.new();canvas.layer=30;add_child(canvas)
	ui=UI.new();ui.game=self;canvas.add_child(ui);_mount(chapter.location)
	if chapter.photo and not chapter.revealed:call_deferred("_discover")
	elif chapter.street_open and chapter.echo_fixed and not chapter.connection_found:call_deferred("_connection")

func _load_art()->void:
	for id:String in ["lucia","zhorik"]:art[id]=load("res://assets/art/"+id+".webp")
	art.kitchen=load("res://assets/art/chapter1/kitchen.webp");art.carmen=load("res://assets/art/chapter1/carmen.webp")
	for id:String in ["courtyard_left","courtyard_right","street_left","street_right","plaza_left","plaza_right","courtyard","courtyard_clear","passage","photograph","lucia_photo","zhorik_pounce","archive_photo","street","street_open","plaza","workshop","harbor"]:art[id]=load("res://assets/art/reboot/"+id+".webp")
	var json_path:="res://assets/art/reboot/regions.json"
	if FileAccess.file_exists(json_path):
		var regions:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(json_path))
		for id:String in regions:
			var b:Array=regions[id];var t:=AtlasTexture.new();t.atlas=art[id];t.region=Rect2(b[0],b[1],b[2]-b[0],b[3]-b[1]);art[id]=t

func _mount(id:String)->void:
	if is_instance_valid(world):remove_child(world);world.queue_free()
	world=World.new();world.game=self;world.scene_id=id;add_child(world)
	selected_item="";ambient.stop();ambient.stream=null
	var stream=load("res://assets/audio/sea_air.wav" if id in ["passage","harbor"] else "res://assets/audio/courtyard_air.wav").duplicate()
	if stream is AudioStreamWAV:stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_begin=0;stream.loop_end=int(stream.get_length()*stream.mix_rate)
	ambient.stream=stream
	if not chapter.muted:ambient.play()
	if id=="harbor":message="Первая глава пройдена. Вы дошли до настоящего моря; у причала ждёт кораблик к Марбелье.";_note("harbor_arrival")
	elif chapter.route_open:message="Путь к гавани закреплён. Кармен ждёт на кухне."
	elif id=="workshop":message="Свет в раме возвращается к началу. Шкивы ременной передачи неподвижны."
	elif chapter.connection_found:message="Отражение и эхо удержали мастерскую. За ней ещё не восстановлен обратный ход."
	elif id=="street":message="Вода бежит к сливу. В ней улица кажется длиннее."
	elif id=="plaza":message="Музыка слышна из сухого фонтана. Гитарист сидит совсем в другой стороне."
	elif chapter.complete:message="Два берега на одном снимке. У лоджии появилась улица."

func change_scene(id:String)->void:
	if transitioning or not chapter.can_enter(id):return
	close_modal();transitioning=true;world.stop();_save_game();ui.fade.mouse_filter=Control.MOUSE_FILTER_STOP
	var t:=create_tween();t.tween_property(ui.fade,"color:a",1.0,.20);await t.finished
	chapter.visit(id);_mount(id);_save_game()
	t=create_tween();t.tween_property(ui.fade,"color:a",0.0,.22);await t.finished
	transitioning=false;ui.fade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if id=="passage":message="Море и озеро… Как они поместились за нашей стеной?";chapter.observe("threshold")

func location_title()->String:return "I · "+TITLES[chapter.location]
func item_name(id:String)->String:return {"photograph":"Старая фотография","mirror":"Зеркало","belt":"Ремень передачи","frame":"Дорожная рамка","jug":"Кувшин с водой" if chapter.jug_filled else "Пустой кувшин"}.get(id,id)
func current_message()->String:
	if save_error:return "Не удалось сохранить. Прогресс остаётся в этой сессии."
	return message
func goal()->String:
	return {"find":"Исследуй дворик","photo":"Исследуй фотографию на солнце","cat":"Устрани разрыв в тени","align":"Совмести тень с порогом","bridge":"Найди непрерывный путь в дверь","entry":"Загляни за стену","archive":"Разберись, что хранит это место","after":"Выйди на улицу","water":"Удержи отражение в воде","reflection":"Свяжи два вида арки","street_done":"Найди отклик на площади","music":"Проведи последний отклик через воду","echo_done":"Удержи путь к мастерской","connection":"Войди в мастерскую","frame":"Верни раме обратный ход","route":"Свяжи раму с настоящей картой","departure":"Соберись с Кармен к морю","harbor":"Первая глава · дорога к морю открыта"}[chapter.stage()]
func can_continue()->bool:
	return not transitioning and (chapter.opened and chapter.location in ["courtyard","kitchen"] or chapter.complete and chapter.location in ["passage","street","plaza"] or chapter.location in ["workshop","harbor"])
func next_place()->String:
	if chapter.location=="courtyard" and chapter.departed:return "harbor"
	if chapter.location=="street" and chapter.connection_found and not chapter.frame_fixed:return "workshop"
	return {"courtyard":"passage","kitchen":"passage","passage":"street","street":"plaza","plaza":"street","workshop":"street","harbor":"courtyard"}[chapter.location]
func continue_title()->String:
	if chapter.location=="courtyard" and chapter.departed:return "К гавани →"
	if chapter.location=="street" and chapter.connection_found and not chapter.frame_fixed:return "В мастерскую →"
	return {"courtyard":"В проход →","kitchen":"В проход →","passage":"На улицу →","street":"На площадь →","plaza":"На улицу →","workshop":"На улицу →","harbor":"В деревню →"}[chapter.location] if chapter.opened else "Исследуй дворик"
func hover_text()->String:return world.tooltip_at(get_global_mouse_position()) if is_instance_valid(world) else ""

func note_text(id:String)->String:return Journey.EXTRA_NOTES.get(id,Panorama.LINES.get(id,NOTES.get(id,id)))

func _note(id:String)->void:
	if chapter.observe(id):new_note=id;audio.play("pickup")
func world_action(id:String)->void:
	if is_instance_valid(world.panorama) and world.panorama.action(id):return
	if id in ["courtyard","kitchen","passage","street","plaza","workshop","harbor"]:change_scene(id);return
	if is_instance_valid(world.journey) and world.journey.act(id):return
	if is_instance_valid(world.episode):world.episode.act(id);return
	match id:
		"box":
			if chapter.photo:message="В ящике больше нет снимков. Этот дворик был снят первым.";world.lucia.react("inspect")
			else:chapter.photo=true;_note("photo");_save_game();_discover()
		"holder":
			if not chapter.photo:message="Полка прогрелась на солнце. На штукатурке — след старого крепления."
			elif chapter.photo_placed:message="Сдвигая и наклоняя снимок, можно менять очертания тени."
			else:
				chapter.photo_placed=true;_note("sun");selected_item="";world.lucia.react("pickup");world.sync()
				message="На полке снимок не дрожит. Но тень двери почему-то разрезана светлой полосой."
		"wall":
			_note("wall")
			if chapter.opened:change_scene("passage")
			elif chapter.try_open():_open_door()
			elif chapter.aligned:message="Дверь почти настоящая… но тень доски заканчивается рядом с порогом."
			else:message="Под пальцами белая штукатурка. Внизу — старый порог и два следа косяков."
		"cord":_note("cord");message="Слишком высоко. Шнур натянут между полотенцем и звоночком.";world.lucia.react("inspect")
		"cat":
			world.cat.react("inspect")
			message="Жорик следит за движущимися бликами. На неподвижный он быстро перестаёт смотреть."
		"mirror":
			if chapter.mirror:message="Зеркало уже в сумке. Им можно направить солнечный блик."
			else:chapter.mirror=true;_note("mirror");world.lucia.react("pickup");message="Зеркало поймало солнце. Жорик сразу повернул голову.";world.sync()
		"watermelon":_note("watermelon");world.lucia.react("happy");message="Кармен: «Арбуз будет у воды. А сейчас — pan con tomate. Не забудь поесть перед дорогой»."
		"carmen":
			_note("carmen")
			if chapter.route_open:
				chapter.departed=true;message="Кармен: «Тогда поедем. Нико уже ждёт у катамарана. И возьмём арбуз — на потом».";audio.play("discovery")
			elif chapter.frame_fixed:message="Кармен: «Впервые в раме появилась дорога. Осталось найти её начало здесь, у нашего порога»."
			elif chapter.connection_found:message="Кармен: «Ты вернула улице длину. Я думала, она больше не вспомнит дорогу»."
			elif chapter.echo_fixed:message="Кармен: «Слышала фонтан? Когда-то он отвечал с другого берега»."
			elif chapter.street_open:message="Кармен: «Не входи в раму с одной стороны, пока не услышишь другую»."
			elif chapter.opened:message="Кармен: «Эта дверь смотрела в другую сторону. Кто её развернул?»"
			elif chapter.photo:message="Кармен: «В том дворе ещё не вешали бельё над полкой. Зачем тебе этот старый снимок?»"
			else:message="Кармен: «Кухня открыта. Разбирай ящик, если хочешь. И не дразни Жорика»."
		"board":message="Старая доска поворачивается вокруг гвоздя. Её тень тянется к стене."
		"tile":_note("tile");message="Под цветами плитка с ласточкой. Её крыло направлено к морю.";world.lucia.react("inspect")
		"basin":
			world.cat.react("inspect")
			var t:=world.create_tween();t.tween_property(world.cat,"position",Vector2(719,539),.5).set_trans(Tween.TRANS_QUAD);t.tween_interval(.5);t.tween_property(world.cat,"position",Vector2(685,585),.6)
			message="В воде — вечер, хотя наверху полдень. Отражение не повторяет небо над головой."
		"harbor_view":message="Слышны чайки. Видимый берег настоящий; пройти туда пока мешает обрыв тени."
		"archive":
			if not chapter.complete:
				scene_kind="archive";transitioning=true;world.stop()
				cutscene.start([[0,"archive_pose"],[.9,"archive_echo"],[2.8,"archive_message"]],4)
			else:show_album("archive")
	_save_game()

func _discover()->void:
	if transitioning:return
	close_modal();world.stop();scene_kind="discover";transitioning=true
	message="";cutscene.start([[0,"lift"],[1.15,"look"],[2.4,"reveal"],[3.6,"cat_notice"],[5.4,"discovery_done"]],6.1)
func _beat(id:String)->void:
	if id.begins_with("frame_") or id.begins_with("cat_") and id in ["cat_thread","cat_niche","cat_belt"]:
		if is_instance_valid(world.journey):world.journey.beat(id)
		return
	if id.begins_with("music_") or id.begins_with("street_"):
		if is_instance_valid(world.episode):world.episode.beat(id)
		return
	match id:
		"connection_notice":audio.play("discovery");message="Отклик вернулся в отражение. Теперь мастерская держится с обеих сторон."
		"connection_commit":chapter.connection_found=true;_note("connection");_save_game()
		"lift":world.lucia.react("pickup")
		"look":
			world.lucia.idle_texture=art.lucia_photo;world.holding=true;message="На снимке — наш дворик. Но откуда эта дверь?"
		"reveal":
			var t:=world.create_tween();t.set_pause_mode(Tween.TWEEN_PAUSE_STOP);t.tween_property(world,"reveal_amount",1.0,.75);audio.play("discovery")
		"cat_notice":
			world.cat.idle_texture=art.zhorik_pounce;world.cat.facing=-1;world.cat.react("inspect")
			var t:=world.create_tween();t.set_pause_mode(Tween.TWEEN_PAUSE_STOP);t.tween_property(world.cat,"position",Vector2(605,552),.65)
			message="Жорик следит за тенью. Она движется… а солнце — нет."
		"discovery_done":chapter.revealed=true;_save_game()
		"door_light":audio.play("discovery");world.lucia.react("inspect");message="Тени соединились. Стена стала глубиной."
		"door_cat":world.cat.react("happy")
		"archive_pose":world.lucia.idle_texture=art.lucia_photo;world.holding=true
		"archive_echo":
			world.archive_display=true;world.photo_sprite.texture=art.archive_photo
			world.photo_sprite.position=world.lucia.position+Vector2(46,-172);world.photo_sprite.scale=Vector2.ONE*.04;world.photo_sprite.z_index=30
			var t:=world.create_tween();t.set_parallel(true);t.tween_property(world.photo_sprite,"position",Vector2(420,225),.8);t.tween_property(world.photo_sprite,"scale",Vector2.ONE*.35,.8)
			audio.play("discovery");world.cat.react("inspect")
		"archive_message":chapter.complete=true;_note("archive");_save_game();message="Один снимок, два берега. Здесь хранят не места — здесь хранят пути между ними."
func _cutscene_finished()->void:
	var was_archive:bool=scene_kind=="archive"
	var was_connection:bool=scene_kind=="connection"
	transitioning=false;world.holding=false;world.archive_display=false;world.photo_sprite.z_index=2;world.photo_sprite.texture=art.photograph;world.lucia.idle_texture=art.lucia
	if is_instance_valid(world.cat):world.cat.idle_texture=art.zhorik
	world.sync();_save_game();scene_kind=""
	if was_archive:show_album("archive")
	elif was_connection:show_album("route")
	elif chapter.street_open and chapter.echo_fixed and not chapter.connection_found:call_deferred("_connection")
func _connection()->void:
	if transitioning or chapter.connection_found:return
	close_modal();world.stop();transitioning=true;scene_kind="connection"
	cutscene.start([[0,"connection_notice"],[1.6,"connection_commit"]],3.2)

func cat_pulled()->void:
	chapter.laundry_clear=true;_note("cat");chapter.move_projection(chapter.light_x,chapter.light_height)
	world.sync();audio.play("gust");message="Полотенце ушло вверх. Теперь дверь отбрасывает целую тень.";_save_game()
func check_progress()->void:
	if chapter.aligned:message="Края совпали со следами косяков. Осталось соединить тень доски с порогом."
	elif chapter.photo_placed and not chapter.laundry_clear:message="Светлая полоса разрывает тень. Найди, что заслоняет солнце."
	elif chapter.photo_placed:message="Тень движется за фотографией. Следы косяков помогают найти её прежнее место."
func _open_door()->void:
	world.stop();selected_item="";scene_kind="door";transitioning=true;_save_game()
	cutscene.start([[0,"door_light"],[1.1,"door_cat"]],2.4)

func ui_action(action:String)->void:
	if transitioning and not (cutscene.running and action in ["pause","close","mute"]):return
	match action:
		"close":close_modal()
		"map":show_map()
		"album":show_album()
		"notebook":show_notebook()
		"hint":show_hint()
		"inventory":ui.show_inventory=not ui.show_inventory
		"pause":show_pause()
		"mute":audio.toggle_mute();chapter.muted=audio.muted;ambient.stop() if chapter.muted else ambient.play();_save_game()
		"walk_left","walk_right":
			if modal=="" and is_instance_valid(world.panorama):world.panorama.walk_side(-1 if action=="walk_left" else 1)
		"next_scene":change_scene(next_place())
		"restart":show_restart()
func close_modal()->void:
	ui.close();modal="";get_tree().paused=false
	for player:AudioStreamPlayer in audio.players:player.stream_paused=false
	ambient.stream_paused=false
func _open(title:String,subtitle:String="")->Control:
	world.stop();modal=title;get_tree().paused=true
	for player:AudioStreamPlayer in audio.players:player.stream_paused=true
	ambient.stream_paused=true
	return ui.open(title,subtitle)
func inspect_item(id:String)->void:
	if transitioning:return
	close_modal();selected_item="" if selected_item==id else id
	if id=="photograph":show_album()
	elif id=="frame":message="Рамка выбрана. Нажми карту на столе справа в лоджии."
	elif id=="belt":message="Ремень выбран. Нажми на два шкива в мастерской."
	elif id=="jug":message="Кувшин выбран. Нажми на кран, рычаг слива или верхнюю чашу фонтана." if selected_item==id else "Кувшин убран в сумку."
	elif chapter.location=="street":message="Зеркало выбрано. Закрепи его под навесом.";world.spot_active=false
	else:message="Зеркало выбрано. Во дворе удерживай кнопку мыши и веди солнечный блик.";world.spot_active=false
func select_token(_a:String,_b:String)->void:pass
func apply_selected(_a:String,_b:String)->void:pass
func drop_token(_a:String,_b:String,_c:String)->void:pass
func show_album(page:String="courtyard")->void:
	var route:bool=page=="route" and chapter.connection_found
	var archive:bool=page in ["archive","route"] and chapter.complete
	var b:=_open("Два берега" if archive else "Фотография","Что исчезло между двумя местами?" if archive else "На снимке дворик узнаваем. Найди то, чего теперь нет.")
	if not chapter.photo:
		ui.label(b,"Фотография ещё не найдена.",Rect2(35,20,830,270),24);return
	ui.picture(b,art.archive_photo if archive else art.photograph,Rect2(35,5,574,324))
	ui.label(b,"Две связи\n\nОтражение удержало путь к мастерской.\n\nФонтан вернул отклик с дальнего конца.\n\n"+("Рама восстановлена. На карте появился выход к гавани." if chapter.frame_fixed else "Внутри предстоит вернуть обратный ход.")+"" if route else "Сохранены берега\n\nМоре и озеро на одном снимке.\n\nЛиния пути обрывается в белом промежутке.\n\nБерега остались. Связь исчезла." if archive else "Синяя дверь\n\nНа снимке над полкой нет полотенца. Тень внизу не прерывается.\n\nСнимок можно поставить на солнечную полку во дворе.",Rect2(637,20,276,280),18)
	if chapter.complete:
		ui.button(b,"Дворик",Rect2(35,342,276,33),show_album.bind("courtyard"),"AlbumCourtyard",15)
		ui.button(b,"Две связи" if chapter.connection_found else "Два берега",Rect2(324,342,276,33),show_album.bind("route" if chapter.connection_found else "archive"),"AlbumArchive",15)
func show_notebook()->void:
	var b:=_open("Блокнот Лусии","Только увиденные факты. Новые записи появляются после твоих действий.")
	var scroll:=ScrollContainer.new();scroll.position=Vector2(34,0);scroll.size=Vector2(880,365);b.add_child(scroll)
	var stack:=VBoxContainer.new();stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(stack)
	if chapter.notes.is_empty():var n:=Label.new();n.text="Пока нет записей. Исследуй дворик.";stack.add_child(n)
	for id:String in chapter.notes:
		var label:=Label.new();label.text="• "+note_text(id);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",19);label.add_theme_color_override("font_color",UI.INK);label.custom_minimum_size=Vector2(825,60);stack.add_child(label)
func show_hint()->void:
	var stage:String=chapter.stage();var level:int=int(chapter.hints.get(stage,0))
	var b:=_open("Подсказка",goal())
	var hint:String=HINTS[stage][maxi(0,level-1)] if level>0 else "Подсказки необязательны. Первая укажет, что стоит заметить; следующая объяснит связь."
	if stage=="align" and level==3:
		var dx:float=(746-chapter.light_x)/2.6
		var dy:float=(320-chapter.light_height)/2.3
		hint="Потяни латунную ручку у фотографии %s примерно на %.0f пикселей и %s на %.0f. Края тени должны совпасть с косяками." % ["вправо" if dx>=0 else "влево",absf(dx),"вверх" if dy>=0 else "вниз",absf(dy)]
	ui.label(b,hint,Rect2(40,20,865,225),24)
	if level<3:ui.button(b,["На что смотреть","Какая связь важна","Следующее действие"][level],Rect2(40,278,391,53),_advance_hint.bind(stage),"HintNext")
func _advance_hint(stage:String)->void:chapter.hints[stage]=mini(3,int(chapter.hints.get(stage,0))+1);_save_game();show_hint()
func show_map()->void:
	var b:=_open("Карта первой главы","После находки в лоджии улица и площадь доступны одновременно. Возвращайся свободно.")
	var ids:=["courtyard","kitchen","passage","street","plaza","workshop","harbor"]
	for i:int in ids.size():
		var id:String=ids[i];var row:int=i/3;var col:int=i%3
		var button:Button=ui.button(b,TITLES[id]+("\nТы здесь" if chapter.location==id else ""),Rect2(40+col*293,8+row*80,276,70),change_scene.bind(id),"Map_"+id,20)
		button.disabled=not chapter.can_enter(id)
	ui.label(b,"Улица: "+("путь удержан" if chapter.street_open else "отражение ещё разорвано")+". Площадь: "+("отклик вернулся" if chapter.echo_fixed else "фонтан ещё не отвечает")+".\n\nМастерская: "+("рама восстановлена" if chapter.frame_fixed else "обратный ход ещё замкнут")+". Гавань: "+("дорога открыта" if chapter.route_open else "найди выход на карте")+". Морская поездка — следующая глава.",Rect2(40,257,865,118),19)
func show_pause()->void:
	var b:=_open("Пауза","Игра сохраняется после действий и переходов. Прогресс v0.7 переносится автоматически; исходное сохранение сохраняется.")
	ui.button(b,"Продолжить",Rect2(40,18,360,53),close_modal,"Resume")
	ui.button(b,"Звук: "+("выключен" if chapter.muted else "включён"),Rect2(40,91,360,53),_mute_pause,"Mute")
	ui.button(b,"Начать заново…",Rect2(40,164,360,53),show_restart,"Restart")
	ui.button(b,"Сохранить и выйти",Rect2(40,237,360,53),_quit_game,"Quit")
	ui.label(b,"ЛКМ — идти и исследовать\nПеретаскивание — снимок, доска, зеркало\nH — помощь, N — блокнот, T — карта\nA — фото, I — сумка, M — звук",Rect2(444,34,432,234),21)
func _mute_pause()->void:ui_action("mute");show_pause()
func show_restart()->void:
	var b:=_open("Начать заново","Это сбросит прогресс текущей версии v0.8. Снимки поездки и прежний прототип остаются.")
	ui.button(b,"Сбросить текущую игру",Rect2(40,70,376,61),_restart,"ConfirmRestart")
	ui.button(b,"Продолжить игру",Rect2(457,70,376,61),close_modal,"CancelRestart")
func _restart()->void:
	cutscene.running=false;transitioning=false;scene_kind=""
	close_modal();chapter=State.new();save_blocked=false;save_error=false;message="Кармен позвала на кухню. Жорик остался возле старого ящика.";_mount("courtyard");_save_game()

func _notification(what:int)->void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:_quit_game()
func _stop_audio()->void:
	if is_instance_valid(ambient):ambient.stop();ambient.stream=null
	if is_instance_valid(audio):
		for p:AudioStreamPlayer in audio.players:p.stop();p.stream=null
func _quit_game()->void:
	if quitting:return
	quitting=true;_save_game();_stop_audio();await get_tree().create_timer(.3,true).timeout;get_tree().quit()
func _save_game()->bool:
	if is_instance_valid(world) and is_instance_valid(world.lucia):
		var p:Vector2=world.lucia.position;chapter.positions[world.scene_id]=[roundi(p.x),roundi(p.y)]
	if test_mode:return true
	if save_blocked:save_error=true;return false
	var f:=FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if f==null:save_error=true;return false
	f.store_string(JSON.stringify(chapter.serialize()));f.close()
	save_error=DirAccess.rename_absolute(save_path+".tmp",save_path)!=OK;return not save_error
func _read_json(path:String)->Variant:
	var j:=JSON.new();return j.data if j.parse(FileAccess.get_file_as_string(path))==OK else null
func _load_game()->void:
	if save_path==SAVE and legacy_path==LEGACY_SAVE and not FileAccess.file_exists(legacy_path):
		for old_path:String in ["user://photograph_v0_6.json","user://photograph_v0_5.json"]:
			if FileAccess.file_exists(old_path):legacy_path=old_path;break
	if (save_path==SAVE or legacy_path!=LEGACY_SAVE) and not FileAccess.file_exists(save_path) and not FileAccess.file_exists(save_path+".tmp") and FileAccess.file_exists(legacy_path):
		var legacy:Variant=_read_json(legacy_path)
		if legacy is Dictionary and chapter.restore(legacy):_save_game();return
	for path:String in [save_path,save_path+".tmp"]:
		if not FileAccess.file_exists(path):continue
		var raw:Variant=_read_json(path)
		if raw is Dictionary and chapter.restore(raw):
			if path!=save_path:DirAccess.rename_absolute(path,save_path)
			return
		var backup:String=path+".invalid-"+str(Time.get_unix_time_from_system()).replace(".","-")+".json"
		if DirAccess.copy_absolute(path,backup)!=OK:save_blocked=true;save_error=true
func _exit_tree()->void:_stop_audio()
