@tool
extends CellObject

@export var draw_debug_shape: bool:
	set(val):
		draw_debug_shape = val
		if Engine.is_editor_hint():
			_get_box_and_shape()
@export var collision_shape_3d: CollisionShape3D


func _ready() -> void:
	if Engine.is_editor_hint():
		_get_box_and_shape()


func _get_box_and_shape():
	if collision_shape_3d == null:
		collision_shape_3d = $CollisionShape3D
	var box := collision_shape_3d.shape as BoxShape3D
	if box == null:
		return
	_sync_editor_debug_mesh_to_collision_shape(collision_shape_3d, box.size, draw_debug_shape)
