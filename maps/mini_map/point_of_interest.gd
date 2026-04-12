@tool
class_name PointOfInterest
extends MapRect

enum Type { TOWN, CITY, LANDMARK }
enum Size { NONE, HORIZONTAL, VERTICAL, BIG }

const TOWN = preload("uid://n6q1vx112to")
const CITY = preload("uid://c0rf0iejkikkd")
const LANDMARK = preload("uid://sq516njue3vy")
const TILE_SIZE: float = TileMover.TILE_SIZE
const NONE_SIZE: Vector2 = Vector2(TILE_SIZE, TILE_SIZE)
const HORIZONTAL_SIZE: Vector2 = Vector2(TILE_SIZE * 2, TILE_SIZE)
const VERTICAL_SIZE: Vector2 = Vector2(TILE_SIZE, TILE_SIZE * 2)
const BIG_SIZE: Vector2 = Vector2(TILE_SIZE * 2, TILE_SIZE * 2)

@export var type: Type = Type.TOWN:
	set(value):
		type = value
		if Engine.is_editor_hint():
			_change_texture()
@export var orientation: Size = Size.NONE:
	set(value):
		orientation = value
		if Engine.is_editor_hint():
			_adjust_dimensions()


func _ready() -> void:
	if Engine.is_editor_hint():
		_change_texture()
		_adjust_dimensions()


func _change_texture() -> void:
	match type:
		Type.TOWN:
			texture = TOWN
		Type.CITY:
			texture = CITY
		Type.LANDMARK:
			texture = LANDMARK


func _adjust_dimensions() -> void:
	match orientation:
		Size.NONE:
			size = NONE_SIZE
		Size.HORIZONTAL:
			size = HORIZONTAL_SIZE
		Size.VERTICAL:
			size = VERTICAL_SIZE
		Size.BIG:
			size = BIG_SIZE
