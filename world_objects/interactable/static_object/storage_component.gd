extends Node

func trigger() -> void:
	var player = get_tree().get_first_node_in_group("player")
	Global.toggle_player.emit()
	player.party_handler.send_player_party_and_storage()
	Global.request_open_storage.emit()
