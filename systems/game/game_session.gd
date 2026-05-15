class_name GameSession
extends RefCounted

var field_root: Node3D
var grid_map: CombinedGridMap


func _init(
		p_field_root: Node3D,
		p_grid_map: CombinedGridMap,
) -> void:
	field_root = p_field_root
	grid_map = p_grid_map
