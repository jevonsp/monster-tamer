class_name TravelHandler
extends Node

@onready var player: Player = $".."


func start_surfing() -> void:
	player.travel_state = Player.TravelState.SURFING
	get_tree().call_group("surf_object", "toggle_mode", TravelBlockerObject.State.PASSABLE)
	await player.walk_one_tile(player.facing_direction)


func stop_surfing() -> void:
	player.travel_state = Player.TravelState.DEFAULT
	get_tree().call_group("surf_object", "toggle_mode", TravelBlockerObject.State.NOT_PASSABLE)


func start_climbing() -> void:
	printerr("IMPLEMENT CLIMBING")


func stop_climbing() -> void:
	printerr("IMPLEMENT CLIMBING")
