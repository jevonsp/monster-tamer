@tool
extends TileMover
class_name NPC
enum Direction {NONE, UP, DOWN, LEFT, RIGHT}
@export var npc_name: String = "NPC"
@export var direction: Direction = Direction.DOWN:
	set(value):
		direction = value
		if Engine.is_editor_hint():
			_update_direction_visual()
@export_multiline var dialogue: Array[String] = []
@export var is_autocomplete: bool = false
@export var is_question: bool = false
var tiles_in_sight: Array[Vector2] = []
var components: Array[NPCComponent] = []
@onready var exclamation_point: AnimatedSprite2D = $ExclamationPoint

var facing_vec: Vector2:
	get:
		return facing_direction
	set(value):
		facing_direction = value


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		_update_direction_visual()
		return
	_set_component_array()
	_connect_signals()


func _physics_process(delta: float) -> void:
	match current_state:
		MoveState.MOVING:
			animate_move(delta)


func _set_component_array() -> void:
	for child in get_children():
		if child is NPCComponent:
			components.append(child)


func _connect_signals() -> void:
	if Engine.is_editor_hint():
		return


func interact(body: CharacterBody2D) -> void:
	var new_facing_direction = (body.global_position - global_position).normalized()
	if new_facing_direction != facing_vec:
		start_turning(new_facing_direction)
	await _say_dialogue()


func _say_dialogue(d: Array[String] = [], autocomplete = null, question = null) -> void:
	var dia = d if not d.is_empty() else dialogue
	var ac = autocomplete if autocomplete != null else is_autocomplete
	var iq = question if question != null else is_question
	Global.send_text_box.emit(self, dia, ac, iq, true)
	await Global.text_box_complete


func trigger() -> void:
	var player = get_tree().get_first_node_in_group("player")
	for c: NPCComponent in components:
		if c.is_active:
			@warning_ignore("redundant_await")
			await c.trigger(player)


func _update_direction_visual() -> void:
	if not is_node_ready():
		return

	var anim_player = get_node("AnimationPlayer") as AnimationPlayer
	if not anim_player:
		return
		
	var dir_vec = _vector_from_dir(direction)
	facing_direction = dir_vec
	
	if animation_tree:
		animation_tree.set("parameters/Idle/blend_position", dir_vec)
		anim_state.travel("Idle")
	else:
		anim_state.travel("Idle")


func _vector_from_dir(dir: Direction) -> Vector2:
	match dir:
		Direction.UP:
			return Vector2.UP
		Direction.DOWN:
			return Vector2.DOWN
		Direction.LEFT:
			return Vector2.LEFT
		Direction.RIGHT:
			return Vector2.RIGHT
		_:
			return Vector2.ZERO


func _direction_from_vector(vector: Vector2) -> Direction:
	match vector:
		Vector2.UP:
			return Direction.UP
		Vector2.DOWN:
			return Direction.DOWN
		Vector2.LEFT:
			return Direction.LEFT
		Vector2.RIGHT:
			return Direction.RIGHT
		_:
			return Direction.NONE


func _get_walk_speed() -> float:
	return 4.0


func animate_exclamation() -> void:
	exclamation_point.visible = true
	exclamation_point.play()
	await exclamation_point.animation_finished
	await get_tree().create_timer(0.1).timeout
	exclamation_point.visible = false
