extends Node


func is_tile_water(tile: Vector2i, map: TileMapLayer) -> bool:
	var data := map.get_cell_tile_data(tile)
	if data == null:
		return false
	return bool(data.get_custom_data("is_water"))


func is_tile_elevated(tile: Vector2i, map: TileMapLayer) -> bool:
	var data := map.get_cell_tile_data(tile)
	if data == null:
		return false
	return bool(data.get_custom_data("is_elevated"))


## Ground tiles under a bridge deck (same grid as overlay art): suppress bridge-layer height so underpass stays band 0.
func is_under_bridge_deck(tile: Vector2i, map: TileMapLayer) -> bool:
	var data := map.get_cell_tile_data(tile)
	if data == null:
		return false
	return bool(data.get_custom_data("under_bridge_deck"))


func terrain_height_level(tile: Vector2i, map: TileMapLayer) -> int:
	if is_tile_elevated(tile, map):
		return 1
	return 0
