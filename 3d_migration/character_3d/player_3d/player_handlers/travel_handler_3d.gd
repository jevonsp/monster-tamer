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


func is_surfing() -> bool:
	return travel_state == TravelState.SURFING


func can_start_surf(edge: GraphEdge, from_cell: Vector3i) -> bool:
	if edge == null or player == null or player.grid_map == null:
		return false
	if edge.move_kind != GraphEdge.MoveKind.SURF:
		return false
	if is_surfing():
		return false
	return player.grid_map.is_land_cell(from_cell) and player.grid_map.is_water_cell(edge.to_cell)


func start_surf() -> void:
	travel_state = TravelState.SURFING


func stop_surf() -> void:
	travel_state = TravelState.DEFAULT


func _connect_signals() -> void:
	Global.location_changed.connect(_on_location_changed)


func _on_location_changed(new_location: Map.Location) -> void:
	if new_location == current_location:
		return
	current_location = new_location
