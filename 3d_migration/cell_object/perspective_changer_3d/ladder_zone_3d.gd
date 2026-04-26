@tool
class_name LadderZone3D
extends CellObject

const BASE_SIZE := 0.938

@export var ladder_length: int = 1:
	set(val):
		if val <= 0:
			return
		ladder_length = val
		if Engine.is_editor_hint():
			update_ladder()

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	update_ladder()


func update_ladder() -> void:
	var box := collision_shape_3d.shape as BoxShape3D
	var new_size_z := BASE_SIZE + (ladder_length - 1)
	box.size.z = new_size_z
	var start_face_z := 0.5 - (BASE_SIZE * 0.5)
	collision_shape_3d.position.z = start_face_z + (new_size_z * 0.5)


func _on_area_entered(area: Area3D) -> void:
	if area is not Player3D:
		return

	(area as Player3D).travel_handler.is_on_ladder = true


func _on_area_exited(area: Area3D) -> void:
	if area is not Player3D:
		return

	(area as Player3D).travel_handler.is_on_ladder = false
