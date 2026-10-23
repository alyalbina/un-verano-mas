extends Control
const Token = preload("res://scripts/puzzle_token.gd")
const Slot = preload("res://scripts/drop_slot.gd")
const Icon = preload("res://scripts/paper_icon.gd")
const INK := Color("354250")
const BLUE := Color("347e9d")
const PAPER := Color("faf2df")
var game: Node
var body: Control
var overlay: Control
var chapter_label: Label
var goal_label: Label
var message_label: Label
var next_button: Button
var inventory_row: Control
var tooltip_label: Label
var fade: ColorRect
var inventory_cache := ""
var show_inventory := true
var left_walk:Button
var right_walk:Button

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel(self,Rect2(20,16,324,59),Color(0.98,0.95,0.87,0.92))
	label(self,"Un Verano Más",Rect2(33,20,300,29),22)
	chapter_label=label(self,"Глава I · Фотография и дорога",Rect2(34,49,297,22),14,BLUE)
	for i: int in 6:
		var titles := ["Карта","Альбом","Блокнот","Сумка","Подсказка","Пауза"]
		var ids := ["map","album","notebook","inventory","hint","pause"]
		var b:Button=button(self,"",Rect2(900+i*58,16,54,52),game.ui_action.bind(ids[i]),"Toolbar_"+ids[i],16)
		icon(b,ids[i],Rect2(15,5,24,24))
		var caption:Label=label(b,"Помощь" if i==4 else titles[i],Rect2(1,31,52,18),12)
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		b.tooltip_text=titles[i]+" · "+["T","A","N","I","H","Esc"][i]
	goal_label=label(self,"",Rect2(0,0,1,1),16,BLUE);goal_label.visible=false
	panel(self,Rect2(280,636,739,66),Color(0.98,0.95,0.87,0.93))
	message_label=label(self,"",Rect2(294,641,710,58),16)
	next_button=button(self,"Дальше",Rect2(1035,644,222,49),game.ui_action.bind("next_scene"),"Continue",17)
	inventory_row=Control.new();inventory_row.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(inventory_row)
	left_walk=button(self,"‹",Rect2(12,552,41,57),game.ui_action.bind("walk_left"),"WalkLeft",32)
	right_walk=button(self,"›",Rect2(1227,552,41,57),game.ui_action.bind("walk_right"),"WalkRight",32)
	left_walk.tooltip_text="Пройти дальше влево · ←";right_walk.tooltip_text="Пройти дальше вправо · →"
	tooltip_label=label(self,"",Rect2(420,115,615,33),17)
	tooltip_label.add_theme_color_override("font_color",Color("fff4d2"))
	tooltip_label.add_theme_color_override("font_shadow_color",Color("352c22"))
	tooltip_label.add_theme_constant_override("shadow_offset_x",1)
	tooltip_label.add_theme_constant_override("shadow_offset_y",1)
	fade=ColorRect.new();fade.color=Color(0,0,0,0);fade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(fade)

func _process(_delta: float) -> void:
	if game==null:return
	var wide:bool=is_instance_valid(game.world) and game.world.is_wide()
	left_walk.visible=wide;right_walk.visible=wide
	left_walk.disabled=game.transitioning or game.modal!="";right_walk.disabled=left_walk.disabled
	chapter_label.text=game.location_title()
	goal_label.text=game.goal()
	message_label.text=game.current_message()
	next_button.text=game.continue_title()
	next_button.disabled=not game.can_continue() or game.transitioning
	var cache: String=JSON.stringify(game.chapter.inventory())+str(game.selected_item)+str(show_inventory)
	if cache!=inventory_cache:
		inventory_cache=cache
		for child:Node in inventory_row.get_children():inventory_row.remove_child(child);child.queue_free()
		if show_inventory:
			var index:=0
			for item:String in game.chapter.inventory():
				var name_short:String={"scarf":"Шарф","photograph":"Фото","horse":"Кукла","tile":"Плитка","ticket":"Билет","mirror":"Зерк.","belt":"Рем.","frame":"Рама","jug":"Вода" if game.chapter.jug_filled else "Кувш."}.get(item,game.item_name(item))
				var b:=button(inventory_row,name_short,Rect2(22+index*50,646,47,48),game.inspect_item.bind(item),"Inventory_"+item,11)
				b.tooltip_text=game.item_name(item)
				index+=1
	if game.modal=="" and not game.transitioning:
		var value: String=game.hover_text()
		tooltip_label.text=value
		var p:Vector2=get_viewport().get_mouse_position()
		tooltip_label.position=Vector2(clampf(p.x+14,15,785),clampf(p.y-42,88,603))
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if value!="" else Input.CURSOR_ARROW)
	else:tooltip_label.text="";Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func style(color: Color=PAPER) -> StyleBoxFlat:
	var result:=StyleBoxFlat.new()
	result.bg_color=color;result.border_color=Color("d7c4a4");result.set_border_width_all(1);result.set_corner_radius_all(8)
	result.shadow_color=Color(0.12,0.09,0.06,0.13);result.shadow_size=2
	return result

func panel(parent: Node, rect: Rect2, color: Color=PAPER) -> Panel:
	var node:=Panel.new();node.position=rect.position;node.size=rect.size;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_theme_stylebox_override("panel",style(color));parent.add_child(node);return node

func label(parent: Node, text: String, rect: Rect2, font: int=20, color: Color=INK) -> Label:
	var node:=Label.new()
	# Set wrap/minimum-size policy before text; assign geometry after parenting.
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.clip_text=false
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_size_override("font_size",font);node.add_theme_color_override("font_color",color)
	node.text=text;parent.add_child(node);node.position=rect.position;node.size=rect.size
	return node

func format_button(node: Button, text: String, rect: Rect2, name_id: String, font: int) -> void:
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.clip_text=false
	node.text=text;node.position=rect.position;node.size=rect.size;node.name=name_id
	node.mouse_filter=Control.MOUSE_FILTER_STOP
	node.add_theme_font_size_override("font_size",font)
	for id:String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:node.add_theme_color_override(id,INK)
	node.add_theme_color_override("font_disabled_color",Color("788479"))
	for id:String in ["normal","hover","pressed","focus","disabled"]:
		node.add_theme_stylebox_override(id,style(PAPER if id=="normal" else (Color("e5e4d6") if id=="disabled" else Color("efd7a2"))))

func button(parent: Node, text: String, rect: Rect2, callback: Callable, name_id: String="", font: int=18) -> Button:
	var node:=Button.new();format_button(node,text,rect,name_id,font);node.pressed.connect(callback);parent.add_child(node);return node

func token(text: String, rect: Rect2, kind: String, item: String, disabled: bool=false) -> Button:
	var node:=Token.new();node.item_id=item;node.data_kind=kind
	format_button(node,text,rect,"Token_"+item,18);node.disabled=disabled
	node.pressed.connect(game.select_token.bind(kind,item));body.add_child(node)
	return node

func slot(text: String, rect: Rect2, kind: String, target: String, disabled: bool=false) -> Button:
	var node:=Slot.new();node.drop_kind=kind;node.target_id=target
	format_button(node,text,rect,"Slot_"+target,18);node.disabled=disabled
	node.pressed.connect(game.apply_selected.bind(kind,target))
	node.dropped.connect(game.drop_token.bind(kind))
	body.add_child(node);return node

func icon(parent:Node, kind:String, rect:Rect2) -> void:
	var node:=Icon.new();node.kind=kind;node.position=rect.position;node.size=rect.size;parent.add_child(node)

func picture(parent: Node, texture: Texture2D, rect: Rect2) -> TextureRect:
	var node:=TextureRect.new()
	node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.texture=texture;node.position=rect.position;node.size=rect.size
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(node);return node

func open(title: String, subtitle: String="") -> Control:
	close()
	overlay=Control.new();overlay.name="Overlay";overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(overlay)
	var shade:=ColorRect.new();shade.color=Color(0.13,0.17,0.23,0.62)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;overlay.add_child(shade)
	var paper:=panel(overlay,Rect2(164,101,952,516));paper.mouse_filter=Control.MOUSE_FILTER_STOP
	label(paper,title,Rect2(29,16,735,39),28)
	button(paper,"Закрыть · Esc",Rect2(773,18,150,37),game.ui_action.bind("close"),"Close",15)
	if subtitle!="":label(paper,subtitle,Rect2(30,61,889,45),16,BLUE)
	body=Control.new();body.name="Body";body.position=Vector2(0,113);body.size=Vector2(952,389)
	body.mouse_filter=Control.MOUSE_FILTER_IGNORE;paper.add_child(body)
	return body

func close() -> void:
	if is_instance_valid(overlay):remove_child(overlay);overlay.queue_free()
	overlay=null;body=null

func _unhandled_input(event:InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	var action:=""
	match event.keycode:
		KEY_ESCAPE:action="pause" if game.modal=="" else "close"
		KEY_H:action="hint"
		KEY_N:action="notebook"
		KEY_I:action="inventory"
		KEY_T:action="map"
		KEY_A:action="album"
		KEY_M:action="mute"
		KEY_R:action="restart"
	if action!="":game.ui_action(action);get_viewport().set_input_as_handled()
