extends Node

enum Direction { UP, DOWN, LEFT, RIGHT }


func vec_from_dir(dir: Direction) -> Vector3i:
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
