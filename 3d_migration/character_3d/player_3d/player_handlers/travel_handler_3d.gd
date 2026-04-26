class_name TravelHandler3D
extends Node

signal side_scrolling_started
signal side_scrolling_finished
signal surfing_started
signal surfing_finished

enum TravelState { DEFAULT, SURFING, BIKING, CLIMBING }

@export var current_location: Map.Location = Map.Location.NONE

var travel_state: TravelState = TravelState.DEFAULT
var is_side_scrolling: bool = false
var is_on_ladder: bool = false

@onready var player: Player3D = $".."


func get_travel_dictionary() -> Dictionary:
	var result = { }

	result["is_side_scrolling"] = is_side_scrolling

	return result


func set_travel_info(travel_dict) -> void:
	if travel_dict.get("is_side_scrolling"):
		is_side_scrolling = travel_dict["is_side_scrolling"]


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
	await PlayerContext3D.walk_segmented_completed
	print("start")
	surfing_started.emit()


func stop_surf() -> void:
	print("stop")
	travel_state = TravelState.DEFAULT
	surfing_finished.emit()


func start_side_scroll() -> void:
	if is_side_scrolling:
		return
	if player != null and player.grid_map != null:
		var ground := player.helper.get_ground_cell(
			player.global_position,
			player.grid_map,
			player.get_height_adjustment(),
		)
		is_side_scrolling = true
		player.global_position = player.cell_to_world(ground)
	else:
		is_side_scrolling = true
	side_scrolling_started.emit()


func stop_side_scroll() -> void:
	if not is_side_scrolling:
		return
	if player != null and player.grid_map != null:
		var ground := player.helper.get_ground_cell(
			player.global_position,
			player.grid_map,
			player.get_height_adjustment(),
		)
		is_side_scrolling = false
		player.global_position = player.cell_to_world(ground)
	else:
		is_side_scrolling = false
	side_scrolling_finished.emit()


func can_move_vertically() -> bool:
	return not is_side_scrolling or is_on_ladder


func _connect_signals() -> void:
	Global.location_changed.connect(_on_location_changed)


func _on_location_changed(new_location: Map.Location) -> void:
	if new_location == current_location:
		return
	current_location = new_location
