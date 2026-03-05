extends Node

func trigger(body: CharacterBody2D) -> void:
	print("would open storage here")
	body.party_handler.send_player_party()
	body.party_handler.send_player_storage()
	Global.toggle_player.emit()
	Global.request_open_storage.emit()
