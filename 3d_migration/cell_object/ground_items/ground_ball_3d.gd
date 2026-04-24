@tool
class_name GroundBall3D
extends CellObject

@export var linked_balls: Array[GroundBall3D] = []


func interact(_player: Player3D) -> void:
	if command_lists.is_empty():
		return
	if command_index >= command_lists.size():
		return
	for command: Command in command_lists[command_index].commands:
		@warning_ignore_start("redundant_await")
		await command.before_trigger()
		await command.trigger()
		await command.after_trigger()
		@warning_ignore_restore("redundant_await")
