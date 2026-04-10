extends Node


func _is_tile_water(tile: Vector2i, map: TileMapLayer) -> bool:
	return map.get_cell_tile_data(tile).get_custom_data("is_water")
