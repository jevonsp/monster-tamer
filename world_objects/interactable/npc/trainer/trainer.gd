@tool
extends NPC
class_name Trainer
@export var vision_range: int = 7:
	set(value):
		vision_range = value
		_update_tiles_in_sight()
@export var party: Array[MonsterData] = []
@export var party_levels: Array[int] = []
@export_subgroup("Dialogue")
@export_multiline var winning_dialogue: Array[String] = []
@export_multiline var losing_dialogue: Array[String] = []
#region Variables
@export_subgroup("Variables")
@export var starting_tile: Vector2 = Vector2.ZERO
@export var initial_direction: Direction = Direction.NONE
@export var is_defeated: bool = false
#endregion

func _ready() -> void:
	super()
	if npc_name == "NPC":
		npc_name = "Trainer"
	starting_tile = global_position
	initial_direction = direction
	if Engine.is_editor_hint():
		_update_tiles_in_sight()
		return
	_update_tiles_in_sight()


func _connect_signals() -> void:
	super()
	Global.step_completed.connect(_check_vision_collision)


func _update_tiles_in_sight() -> void:
	if not is_node_ready():
		return
	if tiles_in_sight == null:
		return
	tiles_in_sight.clear()
	var dir_vec = _vector_from_dir(direction)
	for i in range(1, vision_range):
		var tile = global_position + (dir_vec * TILE_SIZE * i)
		tiles_in_sight.append(tile)


func interact(body: CharacterBody2D) -> void:
	var new_facing_direction = (body.global_position - global_position).normalized()
	if new_facing_direction != facing_vec:
		start_turning(new_facing_direction)
	if not is_defeated:
		await animate_exclamation()
		await _say_dialogue(dialogue)
		Global.player_party_requested.emit()
		_send_trainer_battle()
	else:
		await _say_dialogue(losing_dialogue)


func _check_vision_collision(pos: Vector2) -> void:
	if not is_defeated:
		for i in range(len(tiles_in_sight)):
			if pos == tiles_in_sight[i]:
				Global.player_party_requested.emit()
				Global.toggle_player.emit()
				await animate_exclamation()
				if i > 0:
					await walk_list_tiles([tiles_in_sight[i - 1]])
				await _say_dialogue()
				_send_trainer_battle()


func _send_trainer_battle() -> void:
	Global.trainer_battle_requested.emit(self)
	Global.battle_started.emit()


func reset_position() -> void:
	global_position = starting_tile
	var new_vec = _vector_from_dir(initial_direction)
	start_turning(new_vec)


func on_save_game(saved_data_array: Array[SavedData]) -> void:
	var new_saved_data = SavedData.new()
	
	new_saved_data.node_path = get_path()
	new_saved_data.is_defeated = is_defeated
	
	saved_data_array.append(new_saved_data)


func on_load_game(saved_data_array: Array[SavedData]) -> void:
	for data: SavedData in saved_data_array:
		if data.node_path == get_path():
			if data.is_defeated:
				defeat()


func defeat() -> void:
	is_defeated = true
	if Global.step_completed.is_connected(_check_vision_collision):
		Global.step_completed.disconnect(_check_vision_collision)
	if story_component:
		story_component.trigger()
