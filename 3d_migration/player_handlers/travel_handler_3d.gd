class_name TravelHandler3D
extends Node

enum TravelState { DEFAULT, SURFING, BIKING, CLIMBING }

@export var current_location: Map.Location = Map.Location.NONE

var travel_state: TravelState = TravelState.DEFAULT
var is_sidescrolling: bool = false:
	set(value):
		is_sidescrolling = value
		print("is_sidescrolling: ", is_sidescrolling)

@onready var player: Player3D = $".."


func _connect_signals() -> void:
	Global.location_changed.connect(_on_location_changed)


func _on_location_changed(new_location: Map.Location) -> void:
	if new_location == current_location:
		return
	current_location = new_location
