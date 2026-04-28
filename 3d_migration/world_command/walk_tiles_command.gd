class_name WalkTilesCommand
extends Command

enum Direction { UP, DOWN, LEFT, RIGHT }

@export var tile_list: Array[Direction] = []


func walk_tiles(character: Character3D) -> void:
	if tile_list.is_empty():
		return
	for dir in tile_list:
		character._try_start_move(_vec_from_dir(dir))
		await character.grid_step_landed


func _trigger_impl(owner) -> Flow:
	if owner is not Character3D:
		return Flow.NEXT
	await walk_tiles(owner)
	return Flow.NEXT


func _vec_from_dir(dir: Direction) -> Vector3i:
	match dir:
		Direction.UP:
			return Vector3i.FORWARD
		Direction.DOWN:
			return Vector3i.BACK
		Direction.LEFT:
			return Vector3i.LEFT
		Direction.RIGHT:
			return Vector3i.RIGHT
	return Vector3i.ZERO
