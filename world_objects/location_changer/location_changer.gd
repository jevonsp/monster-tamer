extends Area2D

@export var location_entering: Map.Location = Map.Location.NONE


func _on_body_entered(body: Node2D) -> void:
	if body is not Player:
		return
	Global.location_changed.emit(location_entering)
