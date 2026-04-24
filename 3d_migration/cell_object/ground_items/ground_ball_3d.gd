@tool
class_name GroundBall3D
extends CellObject

@export var linked_balls: Array[GroundBall3D] = []


func interact(_player: Player3D) -> void:
	if command_lists.is_empty():
		return
	if command_index >= command_lists.size():
		return
	await command_lists[command_index].run()
