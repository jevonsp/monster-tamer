class_name PerspectiveChanger3D
extends CellObject

enum Type { NONE, ENTRANCE, EXIT }

@export var type: Type = Type.NONE


func _ready() -> void:
	is_active = true
	blocks_player = false
	masks_player = true
	_update()


func _on_area_entered(area: Area3D) -> void:
	if area is not Player3D:
		return
	await PlayerContext3D.walk_segmented_completed
	match type:
		Type.ENTRANCE:
			PlayerContext3D.travel_handler.is_sidescrolling = true
		Type.EXIT:
			PlayerContext3D.travel_handler.is_sidescrolling = false
