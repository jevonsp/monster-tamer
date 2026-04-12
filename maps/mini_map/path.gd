@tool
class_name Path
extends MapRect

enum Direction { HORIZONTAL, VERTICAL }

const ROUTE_HORIZONTAL = preload("uid://u74f17700rl")
const ROUTE_VERTICAL = preload("uid://5awwq6w35adg")

@export var direction: Direction = Direction.HORIZONTAL:
	set(value):
		direction = value
		if Engine.is_editor_hint():
			_change_texture()


func _ready() -> void:
	if Engine.is_editor_hint():
		_change_texture()


func _change_texture() -> void:
	match direction:
		Direction.HORIZONTAL:
			texture = ROUTE_HORIZONTAL
		Direction.VERTICAL:
			texture = ROUTE_VERTICAL
