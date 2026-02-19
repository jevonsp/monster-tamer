@tool
class_name NPC
extends CharacterBody2D
const TILE_SIZE: int = 16
const WALK_SPEED := 4.0
enum Direction {NONE, UP, DOWN, LEFT, RIGHT}
enum State {IDLE, TURNING, WALKING, JUMPING}
var current_state = State.IDLE
var tile_start_pos: Vector2 = Vector2.ZERO
var tile_target_pos: Vector2 = Vector2.ZERO
var eventual_target_pos: Vector2 = Vector2.ZERO
var move_progress: float = 0.0
@export var direction: Direction = Direction.DOWN:
	set(value):
		direction = value
		if Engine.is_editor_hint():
			_update_direction_visual()
@export_multiline var dialogue: Array[String] = [""]
@export var is_autocomplete: bool = false
@export var is_question: bool = false
@export var facing_vec: Vector2 = Vector2.DOWN
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var anim_state = animation_tree.get("parameters/playback")
var components: Array[NPCComponent] = []


func _ready() -> void:
	if Engine.is_editor_hint():
		_update_direction_visual()
	_set_component_array()
	anim_state.travel("Idle")


func _physics_process(delta: float) -> void:
	match current_state:
		State.WALKING:
			animate_move(delta)


func _set_component_array() -> void:
	for child in get_children():
		if child is NPCComponent:
			components.append(child)


func interact(_body: CharacterBody2D) -> void:
	_say_dialogue()


func _is_facing(dir: Vector2) -> bool:
	return _vector_from_dir(direction) == dir


func _update_direction_visual() -> void:
	if not is_node_ready():
		return

	if not has_node("AnimationPlayer"):
		return

	var anim_player = get_node("AnimationPlayer") as AnimationPlayer
	if not anim_player:
		return


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


func _say_dialogue(d: Array[String] = [""], autocomplete = null, question = null) -> void:
	var dia = d if d != [""] else dialogue
	var ac = autocomplete if autocomplete != null else is_autocomplete
	var iq = question if question != null else is_question
	Global.send_overworld_text_box.emit(self, dia, ac, iq)


func trigger() -> void:
	var player = get_tree().get_first_node_in_group("player")
	for c in components:
		c.trigger(player)


func walk_to_tile(pos: Vector2) -> void:
	var dir_vec = (pos - global_position).normalized()
	eventual_target_pos = pos
	if not _is_facing(dir_vec):
		await start_turning(dir_vec)
	if check_able_to_move(dir_vec):
		current_state = State.WALKING


func start_turning(new_facing_direction: Vector2) -> void:
	animation_tree.set("parameters/Turn/blend_position", new_facing_direction)
	animation_tree.set("parameters/Idle/blend_position", new_facing_direction)
	animation_tree.set("parameters/Walk/blend_position", new_facing_direction)

	facing_vec = new_facing_direction
	ray_cast_2d.target_position = new_facing_direction * TILE_SIZE
	current_state = State.TURNING
	anim_state.travel("Turn")

	await animation_tree.animation_finished

	var blend_dir = facing_vec
	animation_tree.set("parameters/Idle/blend_position", blend_dir)
	current_state = State.IDLE
	anim_state.travel("Idle")


func check_able_to_move(dir: Vector2) -> bool:
	ray_cast_2d.target_position = dir * TILE_SIZE
	ray_cast_2d.force_raycast_update()

	if ray_cast_2d.is_colliding():
		return false

	tile_start_pos = position
	tile_target_pos = position + (dir * TILE_SIZE)
	move_progress = 0.0
	current_state = State.WALKING

	animation_tree.set("parameters/Walk/blend_position", dir)
	anim_state.travel("Walk")
	return true


func animate_move(delta: float) -> void:
	move_progress += WALK_SPEED * delta

	if move_progress < 1.0:
		position = tile_start_pos.lerp(tile_target_pos, move_progress)
		return

	position = tile_target_pos
	move_progress = 0.0

	if global_position.is_equal_approx(eventual_target_pos):
		var last_move_dir = (tile_target_pos - tile_start_pos).normalized()
		if last_move_dir != Vector2.ZERO:
			facing_vec = last_move_dir
			animation_tree.set("parameters/Idle/blend_position", facing_vec)
		
		current_state = State.IDLE
		anim_state.travel("Idle")
		return

	var dir_vec = (eventual_target_pos - global_position).normalized()
	if abs(dir_vec.x) > abs(dir_vec.y):
		dir_vec = Vector2(sign(dir_vec.x), 0)
	else:
		dir_vec = Vector2(0, sign(dir_vec.y))

	if not check_able_to_move(dir_vec):
		current_state = State.IDLE
		anim_state.travel("Idle")


func _on_left_pressed() -> void:
	walk_to_tile(global_position + Vector2(-TILE_SIZE * 5, 0))


func _on_right_pressed() -> void:
	walk_to_tile(global_position + Vector2(TILE_SIZE * 5, 0))


func _on_up_pressed() -> void:
	walk_to_tile(global_position + Vector2(0, -TILE_SIZE))


func _on_down_pressed() -> void:
	walk_to_tile(global_position + Vector2(0, TILE_SIZE * 2))
