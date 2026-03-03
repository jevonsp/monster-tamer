extends Node

func trigger(_body: CharacterBody2D) -> void:
	print("would open storage here")
	Global.toggle_player.emit()
	Global.request_open_storage.emit()
