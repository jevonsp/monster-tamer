class_name GroundBall3D
extends CellObject

@export var linked_balls: Array[GroundBall3D] = []


func _after_command_list_run(flow: Command.Flow) -> void:
	if flow == Command.Flow.STOP:
		return
	deactivate()
	for ball in linked_balls:
		ball.deactivate()
