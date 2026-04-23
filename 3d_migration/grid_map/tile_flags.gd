class_name TileFlags
extends Resource

enum TileType { DEFAULT, STAIRS }

@export var elevation: int = 0
@export var tile_type: TileType = TileType.DEFAULT
@export var is_walkable: bool = true
@export var is_passable: bool = false
@export_range(0.0, 1.0, 0.01) var encounter_rate: float = 0.0
@export var allowed_below_entry_cell: Vector3i = Vector3i.ZERO
@export var allowed_above_entry_cell: Vector3i = Vector3i.ZERO


static func get_allowed_stair_direction_below(cell: Vector3i, direction: Vector3i) -> Vector3i:
	return cell + -direction + Vector3i.DOWN


static func get_allowed_stair_direction_above(cell: Vector3i, direction: Vector3i) -> Vector3i:
	return cell + direction + Vector3i.UP
