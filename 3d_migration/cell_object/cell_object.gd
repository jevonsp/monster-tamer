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
		_update()
@export var blocks_player: bool = false:
	get:
		return _blocks_player
	set(val):
		if _blocks_player == val:
			return
		_blocks_player = val
		_update()
@export var masks_player: bool = true:
	get:
		return _masks_player
	set(val):
		if _masks_player == val:
			return
		_masks_player = val
		_update()

var _is_active: bool = true
var _blocks_player: bool = false
var _masks_player: bool = true


func _ready() -> void:
	_update()


func interact(_player: Player3D) -> void:
	if not is_active:
		return
	if command_lists.is_empty():
		return
	if command_index >= command_lists.size():
		return

	PlayerContext3D.toggle_player.emit(false)
	PlayerContext3D.player.clear_inputs()

	var flow: Command.Flow = await command_lists[command_index].run(self)

	PlayerContext3D.player.clear_inputs()
	PlayerContext3D.toggle_player.emit(true)

	_after_command_list_run(flow)


func change_command_index_to(index: int) -> void:
	if index > command_lists.size():
		return

	command_index = index


func on_save_game(saved_data_array: Array[SavedData]) -> void:
	var new_saved_data = SavedData.new()
	new_saved_data.node_path = get_path()

	new_saved_data.is_active = _is_active
	new_saved_data.blocks_player = _blocks_player
	new_saved_data.masks_player = _masks_player
	new_saved_data.is_visible = visible

	saved_data_array.append(new_saved_data)


func on_before_load_game() -> void:
	pass


func on_load_game(saved_data_array: Array[SavedData]) -> void:
	for data: SavedData in saved_data_array:
		if data.node_path == get_path():
			_is_active = data.is_active
			_blocks_player = data.blocks_player
			_masks_player = data.masks_player
			visible = data.is_visible

	_update()


func _after_command_list_run(_flow: Command.Flow) -> void:
	pass


func _update() -> void:
	visible = _is_active
	if _blocks_player:
		collision_layer = 3
	else:
		collision_layer = 0
	if _masks_player:
		collision_mask = 2
	else:
		collision_mask = 0


func _deactivate() -> void:
	is_active = false
	blocks_player = false
	visible = false
	_update()
