extends Button
var item_id := ""
var data_kind := ""

func _get_drag_data(_at_position: Vector2) -> Variant:
	if disabled: return null
	var preview := Label.new()
	preview.text = text
	preview.add_theme_font_size_override("font_size", 20)
	preview.add_theme_color_override("font_color", Color("243c47"))
	set_drag_preview(preview)
	return {"kind": data_kind, "item": item_id}
