extends Node2D

@onready var player: Player = $Player
@onready var test_map_ground: TileMapLayer = $TestMapGround
@onready var tile_map_bridge: TileMapLayer = $TileMapBridge


func _ready() -> void:
	FieldMaps.register(test_map_ground, tile_map_bridge)
