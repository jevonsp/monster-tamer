class_name TileFlags
extends Resource

enum TileType { DEFAULT, STAIRS, LEDGE }

@export var elevation: int = 0
@export var tile_type: TileType = TileType.DEFAULT
@export var is_walkable: bool = true
@export var is_passable: bool = false
@export var allowed_below_entry_cell: Vector3i = Vector3i.ZERO
@export var allowed_above_entry_cell: Vector3i = Vector3i.ZERO
@export var ledge_direction: Vector3i = Vector3i.ZERO
@export var ledge_landing_cell: Vector3i = Vector3i.ZERO


static func get_allowed_stair_direction_below(cell: Vector3i, direction: Vector3i) -> Vector3i:
	return cell + -direction + Vector3i.DOWN


static func get_allowed_stair_direction_above(cell: Vector3i, direction: Vector3i) -> Vector3i:
	return cell + direction + Vector3i.UP


static func get_ledge_landing_cell(cell: Vector3i, direction: Vector3i) -> Vector3i:
	return cell + (direction * 2) + Vector3i.DOWN
