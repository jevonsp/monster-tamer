extends Node

@warning_ignore_start("unused_signal")
signal walk_segmented_completed(graph_position: Vector3i)
signal toggle_player(value: bool)

@warning_ignore_restore("unused_signal")
var player: Player3D
var camera_3d: Camera3D
var party_handler
var inventory_handler
var story_flag_handler
var travel_handler
var player_info_handler
