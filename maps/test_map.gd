extends TileMapLayer

func _ready() -> void:
	var tiles = get_used_cells()
	
	for tile in tiles:
		print(tile)
