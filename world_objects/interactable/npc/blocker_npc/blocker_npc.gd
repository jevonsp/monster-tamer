@tool
class_name BlockerNPC
extends NPC

enum Response { NONE, DISAPPEAR, MOVE, BESPOKE }
enum State { INCOMPLETE, COMPLETE }

@export var state: State = State.INCOMPLETE
@export var story_trigger: Story.Flag = Story.Flag.NONE
@export var response_type: Response = Response.NONE
@export_multiline var post_trigger_dialogue: Array[String] = []
@export_subgroup("Move")
@export var dir_path: Array[Direction] = []
@export var end_facing: Direction = Direction.NONE

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	super()


func interact(body: CharacterBody2D) -> void:
	match state:
		State.INCOMPLETE:
			super.interact(body)
		State.COMPLETE:
			var toward_player: Vector2 = _get_step_direction_to(body.global_position)
			if toward_player != Vector2.ZERO and toward_player != facing_vec:
				start_turning(toward_player)

			await _say_dialogue(post_trigger_dialogue)


func on_save_game(saved_data_array: Array[SavedData]) -> void:
	var new_saved_data = SavedData.new()

	new_saved_data.node_path = get_path()
	new_saved_data.state = state
	new_saved_data.position = position
	new_saved_data.facing_dir = _direction_from_vector(facing_vec)

	saved_data_array.append(new_saved_data)


func on_load_game(saved_data_array: Array[SavedData]) -> void:
	if not is_node_ready():
		await ready

	for data: SavedData in saved_data_array:
		if data.node_path == get_path():
			state = data.state as State
			if state == State.COMPLETE:
				position = data.position
				direction = data.facing_dir as Direction
				_update_direction_visual()
				_handle_completion()


func _connect_signals() -> void:
	super()
	Global.story_flag_triggered.connect(_on_story_flag_triggered)


func _on_story_flag_triggered(flag: Story.Flag, _value: bool) -> void:
	if flag != story_trigger:
		return
	Global.toggle_player.emit()
	match response_type:
		Response.NONE:
			return
		Response.DISAPPEAR:
			state = State.COMPLETE
		Response.MOVE:
			if dir_path:
				var vec_path: Array[Vector2] = []
				for dir in dir_path:
					vec_path.append(_vector_from_dir(dir))
				await walk_list_dirs(vec_path)
			if end_facing:
				var end_vec = _vector_from_dir(end_facing)
				await start_turning(end_vec)
		Response.BESPOKE:
			pass
	state = State.COMPLETE
	_handle_completion()
	Global.toggle_player.emit()


func _handle_completion() -> void:
	if state == State.INCOMPLETE:
		return
	match response_type:
		Response.DISAPPEAR:
			visible = false
			collision_shape_2d.disabled = true
		Response.MOVE:
			pass
		Response.BESPOKE:
			pass
