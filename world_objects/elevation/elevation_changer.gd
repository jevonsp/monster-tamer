extends Area2D

@export var height_level: int = 1


func _on_body_entered(body: Node2D) -> void:
	if body is not TileMover:
		return
	var tile_mover = body as TileMover

	if tile_mover.height_level < height_level:
		tile_mover.height_level = 1
	Global.player_elevation_changed.emit(tile_mover.height_level)


func _on_body_exited(body: Node2D) -> void:
	if body is not TileMover:
		return
	var tile_mover = body as TileMover

	var current_map = Global.base_map if tile_mover.height_level == 0 else Global.elevated_map
	var tile = tile_mover.get_tile_coords()

	if TileChecker.is_tile_elevated(tile, current_map):
		return

	if tile_mover.height_level <= height_level:
		tile_mover.height_level = 0

	Global.player_elevation_changed.emit(tile_mover.height_level)
