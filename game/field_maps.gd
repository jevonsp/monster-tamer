extends Node

## Single place to assign ground + optional bridge TileMapLayers for the active field.
## Mirrors into Global for existing code paths.
var ground: TileMapLayer
var bridge: TileMapLayer


func register(ground_layer: TileMapLayer, bridge_layer: TileMapLayer = null) -> void:
	ground = ground_layer
	bridge = bridge_layer
	Global.ground_map = ground_layer
	Global.world_map = ground_layer
	Global.bridge_map = bridge_layer
