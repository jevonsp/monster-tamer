@tool
class_name LadderZone3D
extends CellObject

const BASE_SIZE := 0.938

@export var ladder_length: int = 1:
	set(val):
		if val <= 0:
			return
		ladder_length = val
		if is_inside_tree() or Engine.is_editor_hint():
			update_ladder()
@export var collision_shape_3d: CollisionShape3D
@export var draw_debug_shape: bool:
	set(val):
		draw_debug_shape = val
		if Engine.is_editor_hint():
			_get_box_and_shape()


func _ready() -> void:
	update_ladder()
	if Engine.is_editor_hint():
		_get_box_and_shape()


func update_ladder() -> void:
	if collision_shape_3d == null:
		return
	var box := collision_shape_3d.shape as BoxShape3D
	var new_size_z := BASE_SIZE + (ladder_length - 1)
	box.size = Vector3(BASE_SIZE, BASE_SIZE, new_size_z)

	var start_face_z := 0.5 - (BASE_SIZE * 0.5)
	collision_shape_3d.position.z = start_face_z + (new_size_z * 0.5)
	_get_box_and_shape()


func _on_area_entered(area: Area3D) -> void:
	if area is not Player3D:
		return
	(area as Player3D).travel_handler.is_on_ladder = true


func _on_area_exited(area: Area3D) -> void:
	if area is not Player3D:
		return
	(area as Player3D).travel_handler.is_on_ladder = false


func _get_box_and_shape():
	if collision_shape_3d == null:
		return
	var box := collision_shape_3d.shape as BoxShape3D
	if box == null:
		return
	_sync_editor_debug_mesh_to_collision_shape(collision_shape_3d, box.size, draw_debug_shape)
