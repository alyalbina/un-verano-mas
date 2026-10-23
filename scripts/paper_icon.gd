extends Control
## Original vector stamps for the UI; painted characters and environments are separate raster assets.
var kind := "bread"
const BLUE := Color("347fa1")
const BROWN := Color("ac703c")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	draw_set_transform(size * 0.5, 0.0, size / Vector2(100, 100))
	match kind:
		"map":
			draw_polyline(PackedVector2Array([Vector2(-35,-31),Vector2(-12,-21),Vector2(12,-31),Vector2(35,-20),Vector2(35,31),Vector2(12,20),Vector2(-12,31),Vector2(-35,20),Vector2(-35,-31)]),BLUE,6,true)
			for x:int in [-12,12]:draw_line(Vector2(x,-23),Vector2(x,24),BLUE,4,true)
		"album","notebook":
			draw_style_box(_box(Color("d9bf8f"),6),Rect2(-33,-37,66,74))
			draw_line(Vector2(-20,-34),Vector2(-20,34),BROWN,4,true)
			if kind=="album":draw_rect(Rect2(-8,-20,30,35),Color("fbf0d7"));draw_circle(Vector2(7,-2),7,BLUE)
			else:
				for y:int in [-13,1,15]:draw_line(Vector2(-8,y),Vector2(23,y),BLUE,4,true)
		"inventory":
			draw_style_box(_box(Color("b86b50"),9),Rect2(-33,-16,66,52))
			draw_arc(Vector2(0,-15),21,PI,TAU,20,BROWN,6,true)
			draw_line(Vector2(-29,2),Vector2(29,2),Color("e3b884"),4,true)
		"hint":
			draw_circle(Vector2(0,-10),24,Color("e2b35a"))
			draw_line(Vector2(-12,14),Vector2(-12,27),BROWN,4,true)
			draw_line(Vector2(12,14),Vector2(12,27),BROWN,4,true)
			draw_line(Vector2(-12,29),Vector2(12,29),BROWN,5,true)
		"pause":
			for x:int in [-18,18]:draw_style_box(_box(BLUE,4),Rect2(x-7,-29,14,58))
		"bread":
			draw_style_box(_box(Color("dba14e"), 20), Rect2(-35, -22, 70, 45))
			for x: int in [-16, 0, 16]: draw_line(Vector2(x-5, -12), Vector2(x+5, 10), Color("fff0be"), 3, true)
		"tomato":
			draw_circle(Vector2.ZERO, 29, Color("d96949"))
			draw_circle(Vector2(-7, -8), 6, Color("f6af72"))
			for i: int in 5: draw_line(Vector2(0,-22), Vector2.from_angle(i*TAU/5)*16 + Vector2(0,-22), Color("65884c"), 3,true)
		"oil", "syrup":
			draw_style_box(_box(Color("8fa663") if kind=="oil" else Color("c78837"),7),Rect2(-18,-18,36,49))
			draw_rect(Rect2(-9,-36,18,21),BROWN)
			draw_rect(Rect2(-17,-9,34,23),Color("f6e3af"))
			draw_circle(Vector2.ZERO,7,Color("6a8649") if kind=="oil" else BROWN)
		"water":
			draw_colored_polygon(PackedVector2Array([Vector2(-24,-28),Vector2(24,-28),Vector2(17,30),Vector2(-17,30)]),Color("c5e6e6"))
			draw_line(Vector2(-22,-10),Vector2(22,-10),BLUE,3,true)
		"coffee":
			draw_arc(Vector2(21,1),16,-PI*.6,PI*.6,20,BROWN,5,true)
			draw_style_box(_box(Color("efe0bd"),8),Rect2(-30,-18,51,42))
			draw_line(Vector2(-23,-12),Vector2(16,-12),Color("6b4731"),6,true)
			for i: int in 2: draw_arc(Vector2(-12+i*17,-27),8,PI,TAU,12,BROWN,2,true)
		"catfood":
			draw_style_box(_box(BLUE,12),Rect2(-34,-2,68,33))
			for i: int in 5: draw_circle(Vector2(-23+i*11,-3),7,BROWN)
		"ceramics", "tile":
			draw_style_box(_box(Color("efd47c"),5),Rect2(-33,-33,66,66))
			for i: int in 4:
				var center: Vector2 = Vector2.from_angle(i*TAU/4)*21
				draw_circle(center,9,BLUE)
			draw_circle(Vector2.ZERO,8,Color("fcf1cf"))
		"threads":
			for i: int in 3:
				var x := -28.0+i*28
				draw_rect(Rect2(x-10,-24,20,48),[Color("c46a6d"),BLUE,Color("a1b765")][i])
				draw_line(Vector2(x-14,-25),Vector2(x+14,-25),BROWN,4,true)
				draw_line(Vector2(x-14,25),Vector2(x+14,25),BROWN,4,true)
		"tube":
			draw_style_box(_box(Color("c99962"),8),Rect2(-12,-36,24,72))
			draw_line(Vector2(-12,-25),Vector2(12,-25),BROWN,4,true)
		"tie":
			draw_arc(Vector2.ZERO,27,0.2,TAU-0.4,40,Color("c96d64"),7,true)
			draw_line(Vector2(24,-9),Vector2(35,20),Color("c96d64"),6,true)
		"clip":
			draw_line(Vector2(-20,30),Vector2(13,-33),BROWN,12,true)
			draw_line(Vector2(-9,32),Vector2(24,-31),Color("dca66a"),10,true)
		"ticket":
			draw_style_box(_box(Color("eacda0"),5),Rect2(-41,-25,82,50))
			for x: int in [-26,0,26]:draw_line(Vector2(x,-18),Vector2(x,18),BROWN,2,true)
		"scarf":
			draw_style_box(_box(Color("d78487"),5),Rect2(-14,-37,28,74))
		"photograph":
			draw_style_box(_box(Color("efe2c3"),3),Rect2(-39,-30,78,60))
			draw_rect(Rect2(-31,-22,62,40),Color("a9855e"))
	draw_set_transform(Vector2.ZERO)

func _box(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=color
	style.set_corner_radius_all(radius)
	return style
