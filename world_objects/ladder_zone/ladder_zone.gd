extends Area2D


func _ready() -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body is TileMover:
		var player = body as Player
		if player.travel_state != Player.TravelState.CLIMBING:
			player.travel_state = Player.TravelState.CLIMBING


func _on_body_exited(body: Node2D) -> void:
	if body is TileMover:
		var player = body as Player
		if player.travel_state == Player.TravelState.CLIMBING:
			player.travel_state = Player.TravelState.DEFAULT
