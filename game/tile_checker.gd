extends Node


func _subtiles_per_axis(map: TileMapLayer) -> int:
	if map == null or map.tile_set == null:
		return 1
	var ts: Vector2i = map.tile_set.tile_size
	if ts.x <= 0 or ts.y <= 0 or ts.x != ts.y:
		return 1
	var step := int(TileMover.TILE_SIZE)
	if step % ts.x != 0:
		return 1
	return step / ts.x


func is_tile_water(logical_cell: Vector2i, map: TileMapLayer) -> bool:
	if map == null:
		return false
	var subtiles := _subtiles_per_axis(map)
	var origin := Vector2i(logical_cell.x * subtiles, logical_cell.y * subtiles)
	for y in range(subtiles):
		for x in range(subtiles):
			var mc := origin + Vector2i(x, y)
			var data := map.get_cell_tile_data(mc)
			if data == null or not data.get_custom_data("is_water"):
				return false
	return true


func is_tile_elevated(logical_cell: Vector2i, map: TileMapLayer) -> bool:
	if map == null:
		return false
	var subtiles := _subtiles_per_axis(map)
	var origin := Vector2i(logical_cell.x * subtiles, logical_cell.y * subtiles)
	for y in range(subtiles):
		for x in range(subtiles):
			var mc := origin + Vector2i(x, y)
			var data := map.get_cell_tile_data(mc)
			if data == null or not data.get_custom_data("is_elevated"):
				return false
	return true
