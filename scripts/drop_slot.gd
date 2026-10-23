extends Button
signal dropped(item: String, target: String)
var drop_kind := ""
var target_id := ""

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return not disabled and data is Dictionary and data.get("kind") == drop_kind and data.get("item") is String

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if _can_drop_data(_at_position, data): dropped.emit(data.item, target_id)
