extends Node

signal walk_segmented_completed(graph_position: Vector3i)
signal toggle_player(value: bool)

var player: Player3D
var camera_3d: Camera3D
