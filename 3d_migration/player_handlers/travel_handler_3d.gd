class_name TravelHandler3D
extends Node

@export var current_location: Map.Location = Map.Location.NONE

var is_sidescrolling: bool = false:
	set(value):
		is_sidescrolling = value
		print("is_sidescrolling: ", is_sidescrolling)

@onready var player: Player3D = $".."


func start_surfing() -> void:
	player.travel_state = player.TravelState.SURFING
	get_tree().call_group("surf_object", "toggle_mode", TravelBlockerObject.State.PASSABLE)
	await player.walk_one_step_along_facing()


func stop_surfing() -> void:
	player.travel_state = player.TravelState.DEFAULT
	get_tree().call_group("surf_object", "toggle_mode", TravelBlockerObject.State.NOT_PASSABLE)


func start_climbing() -> void:
	printerr("IMPLEMENT CLIMBING")


func stop_climbing() -> void:
	printerr("IMPLEMENT CLIMBING")


func _connect_signals() -> void:
	Global.location_changed.connect(_on_location_changed)


func _on_location_changed(new_location: Map.Location) -> void:
	if new_location == current_location:
		return
	current_location = new_location
