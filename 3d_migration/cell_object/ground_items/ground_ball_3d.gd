class_name GroundBall3D
extends CellObject

@export var linked_balls: Array[GroundBall3D] = []


func interact(_player: Player3D) -> void:
	if not is_active:
		return
	if command_lists.is_empty():
		return
	if command_index >= command_lists.size():
		return
	var flow: Command.Flow = await command_lists[command_index].run(self)
	if flow == Command.Flow.STOP:
		return

	_deactivate()
	for ball in linked_balls:
		ball._deactivate()
