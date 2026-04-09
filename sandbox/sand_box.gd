extends Node2D

@onready var player: Player = $Player
@onready var test_map: TileMapLayer = $TestMap


func _ready() -> void:
	player.current_map = test_map
