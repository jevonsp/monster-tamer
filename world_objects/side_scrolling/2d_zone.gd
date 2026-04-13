extends Area2D

enum Type { NONE, ENTER, EXIT }

@export var type: Type = Type.NONE


func _on_body_entered(body: Node2D) -> void:
	if body is not Player:
		return
	if type == Type.ENTER:
		(body as Player).travel.is_sidescrolling = true


func _on_body_exited(body: Node2D) -> void:
	if body is not Player:
		return
	if type == Type.EXIT:
		(body as Player).travel.is_sidescrolling = false
