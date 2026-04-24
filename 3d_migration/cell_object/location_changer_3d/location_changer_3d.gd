@tool
class_name LocationChanger
extends CellObject

@export var location_entering: Map.Location = Map.Location.NONE


func _on_area_entered(area: Area3D) -> void:
	if area is not Player3D:
		return
	Global.location_changed.emit(location_entering)
