extends TileMapLayer

func _ready() -> void:
	var tiles = get_used_cells()
	
	for tile in tiles:
		var is_water = true if get_cell_atlas_coords(tile) == Vector2i(2, 0) else false
		if is_water:
			print("is_water: ", tile)


func create_surf_object(tile: Vector2i) -> void:
	pass


func toggle_surf_objects(active: bool) -> void:
	pass
