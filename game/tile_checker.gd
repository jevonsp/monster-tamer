extends Node


func is_tile_water(tile: Vector2i, map: TileMapLayer) -> bool:
	return map.get_cell_tile_data(tile).get_custom_data("is_water")


func is_tile_elevated(tile: Vector2i, map: TileMapLayer) -> bool:
	if map == null:
		return false
	var data = map.get_cell_tile_data(tile)
	if not data:
		return false
	var elevated = data.get_custom_data("is_elevated")

	return elevated
