@tool
class_name CellObject
extends Area3D

@export var command_lists: Array[CommandList] = []
@export var command_index: int = 0
@export var is_active: bool = true:
	get:
		return _is_active
	set(val):
		if _is_active == val:
			return
		_is_active = val
		if Engine.is_editor_hint():
			_update()
@export var blocks_player: bool = false:
	get:
		return _blocks_player
	set(val):
		if _blocks_player == val:
			return
		_blocks_player = val
		if Engine.is_editor_hint():
			_update()
@export var masks_player: bool = true:
	get:
		return _masks_player
	set(val):
		if _masks_player == val:
			return
		_masks_player = val
		if Engine.is_editor_hint():
			_update()

var _is_active: bool = true
var _blocks_player: bool = false
var _masks_player: bool = true


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
	_masks_player = _is_active
	visible = _is_active
	if _blocks_player:
		collision_layer = 3
	else:
		collision_layer = 0
	if _masks_player:
		collision_mask = 2
	else:
		collision_mask = 0
