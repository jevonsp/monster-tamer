class_name BlockerObject
extends Area2D

enum State { NOT_PASSABLE, PASSABLE }

@export var state: State = State.NOT_PASSABLE
@export_subgroup("Text")
@export_multiline var cant_interact_text: String = ""
@export_multiline var question_interact_text: String = ""

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_apply_state_to_collision()


func interact(_body: Player) -> void:
	pass


func toggle_mode(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	_apply_state_to_collision()


func _apply_state_to_collision() -> void:
	match state:
		State.NOT_PASSABLE:
			collision_shape_2d.disabled = false
		State.PASSABLE:
			collision_shape_2d.disabled = true


func on_save_game(saved_data_array: Array[SavedData]) -> void:
	var new_saved_data = SavedData.new()

	new_saved_data.node_path = get_path()
	new_saved_data.state = state as int

	saved_data_array.append(new_saved_data)


func on_load_game(saved_data_array: Array[SavedData]) -> void:
	for data: SavedData in saved_data_array:
		if data.node_path == get_path():
			state = data.state as State
			_apply_state_to_collision()
