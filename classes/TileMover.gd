class_name TileMover
extends CharacterBody2D

signal finished_turn
signal finished_walk_segment

enum MoveState { IDLE, TURNING, MOVING, JUMPING }

const TILE_SIZE: float = 16.0

var current_state: MoveState = MoveState.IDLE
var facing_direction: Vector2 = Vector2.ZERO
var tile_start_pos: Vector2 = Vector2.ZERO
var tile_target_pos: Vector2 = Vector2.ZERO
var move_progress: float = 0.0
var eventual_target_pos: Vector2 = Vector2.ZERO

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var anim_state: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var ray_cast_2d: RayCast2D = $RayCast2D


func _ready() -> void:
	sync_tile_positions()
	eventual_target_pos = global_position


func sync_tile_positions() -> void:
	tile_start_pos = position
	tile_target_pos = position
	eventual_target_pos = global_position


func start_turning(new_facing_direction: Vector2) -> void:
	if new_facing_direction == facing_direction:
		return

	_begin_turn(new_facing_direction)
	await animation_tree.animation_finished
	_finish_turn()


func try_start_move(dir: Vector2) -> bool:
	ray_cast_2d.target_position = dir * TILE_SIZE
	ray_cast_2d.force_raycast_update()

	if ray_cast_2d.is_colliding():
		return false

	tile_start_pos = position
	tile_target_pos = position + (dir * TILE_SIZE)
	move_progress = 0.0
	current_state = MoveState.MOVING
	animation_tree.set("parameters/Walk/blend_position", dir)
	anim_state.travel("Walk")
	return true


func check_able_to_move(dir: Vector2) -> bool:
	return try_start_move(dir)


func advance_move(delta: float) -> bool:
	move_progress += _get_walk_speed() * delta

	if move_progress < 1.0:
		position = tile_start_pos.lerp(tile_target_pos, move_progress)
		return false

	position = tile_target_pos
	move_progress = 0.0
	return true


func finish_move_to_idle(last_move_dir: Vector2 = Vector2.ZERO) -> void:
	if last_move_dir != Vector2.ZERO:
		facing_direction = last_move_dir
	animation_tree.set("parameters/Idle/blend_position", facing_direction)
	current_state = MoveState.IDLE
	anim_state.travel("Idle")


func walk_list_tiles(tiles: Array[Vector2]) -> void:
	for tile in tiles:
		await walk_to_tile(tile)
		await finished_walk_segment


func walk_to_tile(pos: Vector2) -> void:
	var dir_vec = _get_step_direction_to(pos)
	eventual_target_pos = pos

	if global_position.is_equal_approx(eventual_target_pos):
		finished_walk_segment.emit()
		return

	if not _is_facing(dir_vec):
		await start_turning(dir_vec)

	if check_able_to_move(dir_vec):
		current_state = MoveState.MOVING
	else:
		finished_walk_segment.emit()


func walk_one_tile(dir: Vector2) -> void:
	var cardinal_dir = Vector2(sign(dir.x), sign(dir.y))
	if abs(cardinal_dir.x) > abs(cardinal_dir.y):
		cardinal_dir = Vector2(cardinal_dir.x, 0)
	elif abs(cardinal_dir.y) > 0.0:
		cardinal_dir = Vector2(0, cardinal_dir.y)
	else:
		cardinal_dir = Vector2.ZERO

	if cardinal_dir == Vector2.ZERO:
		finished_walk_segment.emit()
		return

	await walk_to_tile(global_position + (cardinal_dir * TILE_SIZE))


func animate_move(delta: float) -> void:
	if not advance_move(delta):
		return

	_on_walk_step_completed()

	if global_position.is_equal_approx(eventual_target_pos):
		finish_move_to_idle((tile_target_pos - tile_start_pos).normalized())
		finished_walk_segment.emit()
		return

	var dir_vec = _get_step_direction_to(eventual_target_pos)
	if not check_able_to_move(dir_vec):
		finish_move_to_idle((tile_target_pos - tile_start_pos).normalized())
		finished_walk_segment.emit()


func _get_walk_speed() -> float:
	return 4.0


func _set_blend_positions(dir: Vector2) -> void:
	animation_tree.set("parameters/Turn/blend_position", dir)
	animation_tree.set("parameters/Idle/blend_position", dir)
	animation_tree.set("parameters/Walk/blend_position", dir)


func _begin_turn(new_facing_direction: Vector2) -> void:
	_set_blend_positions(new_facing_direction)
	facing_direction = new_facing_direction
	ray_cast_2d.target_position = new_facing_direction * TILE_SIZE
	current_state = MoveState.TURNING
	anim_state.travel("Turn")


func _finish_turn() -> void:
	animation_tree.set("parameters/Idle/blend_position", facing_direction)
	current_state = MoveState.IDLE
	anim_state.travel("Idle")
	finished_turn.emit()


func _on_walk_step_completed() -> void:
	pass


func _is_facing(dir: Vector2) -> bool:
	return facing_direction == dir


func _get_step_direction_to(target_pos: Vector2) -> Vector2:
	var dir_vec = (target_pos - global_position).normalized()
	if abs(dir_vec.x) > abs(dir_vec.y):
		return Vector2(sign(dir_vec.x), 0)
	if abs(dir_vec.y) > 0.0:
		return Vector2(0, sign(dir_vec.y))
	return Vector2.ZERO
