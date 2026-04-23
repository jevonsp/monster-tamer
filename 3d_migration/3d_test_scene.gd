extends Node3D

@onready var grid_map: CustomGridMap = $GridMap
@onready var player: Player3D = $Player3D


func _ready() -> void:
	if player and grid_map:
		player.grid_map = grid_map
		player.helper.used_cells = grid_map.get_used_cells()
