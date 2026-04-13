extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).notify_ladder_zone_entered()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		(body as Player).notify_ladder_zone_exited()
