extends Node

func trigger(body: CharacterBody2D) -> void:
	Global.toggle_player.emit()
	body.party_handler.send_player_party_and_storage()
	Global.request_open_storage.emit()
