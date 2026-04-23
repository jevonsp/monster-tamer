@tool
class_name CellObject
extends Area3D

@export var command_lists: Array[CommandList] = []
@export var command_index: int = 0
@export var is_active: bool = true:
	set(val):
		is_active = val
		if Engine.is_editor_hint():
			_update()
@export var blocks_player: bool = false:
	set(val):
		blocks_player = val
		if Engine.is_editor_hint():
			_update()
@export var masks_player: bool = true:
	set(val):
		masks_player = val
		if Engine.is_editor_hint():
			_update()


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


func _update() -> void:
	if not is_node_ready():
		return
	masks_player = is_active
	visible = is_active
	if blocks_player:
		collision_layer = 3
	else:
		collision_layer = 0
	if masks_player:
		collision_mask = 2
	else:
		collision_mask = 0
