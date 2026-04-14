@tool
class_name Trainer
extends NPC

@export var vision_range: int = 7:
	set(value):
		vision_range = value
		_update_tiles_in_sight()
@export var party: Array[MonsterData] = []
@export var party_levels: Array[int] = []
@export var money_multiplier: float = 1.0
@export var after_battle_components: Array[NPCComponent] = []
@export_subgroup("Dialogue")
@export_multiline var winning_dialogue: Array[String] = []
@export_multiline var losing_dialogue: Array[String] = []
@export_subgroup("Variables")
@export var starting_tile: Vector2 = Vector2.ZERO
@export var initial_direction: Direction = Direction.NONE
@export var is_defeated: bool = false


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
	_connect_signals()


func interact(body: CharacterBody2D) -> void:
	var toward_player: Vector2 = _get_step_direction_to(body.global_position)
	if toward_player != Vector2.ZERO and toward_player != facing_vec:
		start_turning(toward_player)
	if not is_defeated:
		await animate_exclamation()
		await _say_dialogue(dialogue)
		Party.player_party_requested.emit()
		_send_trainer_battle()
	else:
		await _say_dialogue(losing_dialogue)


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


func _connect_signals() -> void:
	super()
	if not Global.step_completed.is_connected(_check_vision_collision):
		Global.step_completed.connect(_check_vision_collision)
	if not Battle.battle_ended.is_connected(_on_battle_ended):
		Battle.battle_ended.connect(_on_battle_ended)


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


func _check_vision_collision(pos: Vector2) -> void:
	if not is_defeated:
		for i in range(len(tiles_in_sight)):
			if pos == tiles_in_sight[i]:
				Party.player_party_requested.emit()
				var interfaces := get_tree().get_first_node_in_group("interfaces")
				if interfaces and interfaces.has_method("begin_field_suppress"):
					interfaces.begin_field_suppress()
				await animate_exclamation()
				if i > 0:
					await walk_list_tiles([tiles_in_sight[i - 1]])
				await _say_dialogue()
				_send_trainer_battle()


func _send_trainer_battle() -> void:
	Battle.trainer_battle_requested.emit(self)
	Battle.battle_started.emit()


func _on_battle_ended(enemy_trainer: Trainer) -> void:
	if enemy_trainer != self:
		return
	if after_battle_components.is_empty():
		return
	await _invoke_components_phase(after_battle_components)
