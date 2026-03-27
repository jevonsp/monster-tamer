@tool
class_name BlockerNPC
extends NPC

enum Response { NONE, DISAPPEAR, MOVE, BESPOKE }

@export var story_trigger: Story.Flag = Story.Flag.NONE
@export var response_type: Response = Response.NONE
@export_multiline var post_trigger_dialogue: Array[String] = []
@export var is_complete: bool = false
@export_subgroup("Move")
@export var dir_path: Array[Direction] = []
@export var end_facing: Direction = Direction.NONE

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	super()


func interact(body: CharacterBody2D) -> void:
	if not is_complete:
		super.interact(body)
	else:
		var toward_player: Vector2 = _get_step_direction_to(body.global_position)
		if toward_player != Vector2.ZERO and toward_player != facing_vec:
			start_turning(toward_player)

		await _say_dialogue(post_trigger_dialogue)


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
			is_complete = true
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
	is_complete = true
	_handle_completion()
	Global.toggle_player.emit()


func _handle_completion() -> void:
	if not is_complete:
		return
	match response_type:
		Response.DISAPPEAR:
			visible = false
			collision_shape_2d.disabled = true
		Response.MOVE:
			pass
		Response.BESPOKE:
			pass
