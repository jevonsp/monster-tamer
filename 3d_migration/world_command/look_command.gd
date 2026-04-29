class_name LookCommand
extends Command

enum Direction { UP, DOWN, LEFT, RIGHT }

@export var look_list: Array[Direction] = []


func look_dirs(character: Character3D) -> bool:
	if look_list.is_empty():
		return true
	var directions: Array[Vector3i] = []
	for dir: Direction in look_list:
		directions.append(_vec_from_dir(dir))
	return await character.look_directions(directions)


func _trigger_impl(owner) -> Flow:
	if owner is not Character3D:
		return Flow.NEXT
	if await look_dirs(owner):
		return Flow.NEXT
	return Flow.STOP


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
