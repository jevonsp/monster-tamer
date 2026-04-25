class_name Character3D
extends Area3D

signal turn_started(facing: Vector3i)
signal turn_finished
signal move_step_started(step: Vector3i, to_cell: Vector3i)
signal grid_step_landed(ground: Vector3i)
signal walk_reached_idle

enum MoveState { IDLE, TURNING, MOVING, LEDGE_JUMPING }

const TURN_DURATION := 0.1
const WALK_ANIM_LENGTH_SEC := 0.8
const HEIGHT_ADJUSTMENT := Vector3(0.5, 2.5, 0.5)

@export var ray_cast_3d: RayCast3D
@export var walk_speed := 5.0
@export var ledge_jump_speed := 2.0
@export var ledge_jump_height := 1.0
@export var facing_grid: Vector3i = Vector3i(0, 0, 1)

var anim_helper := AnimationHelper.new()
var helper := MovementHelper.new()
var grid_map: CustomGridMap
var _facing_grid: Vector3i = Vector3i(0, 0, 1)
var _current_state: MoveState = MoveState.IDLE
var _turn_timer: float = 0.0
var _moving := false
var _tile_start_world: Vector3
var _tile_target_world: Vector3
var _move_progress: float = 0.0

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var shadow: AnimatedSprite3D = $BottomSprite3D/Shadow


func _ready() -> void:
	if shadow.visible:
		shadow.visible = false


func will_collide() -> bool:
	ray_cast_3d.force_raycast_update()
	return ray_cast_3d.is_colliding()


func can_move_in() -> bool:
	return not will_collide()


func walk_one_step_along_facing() -> void:
	if grid_map == null:
		return
	if _current_state != MoveState.IDLE or _moving:
		return
	if not _try_begin_slide(_facing_grid):
		return
	if _current_state != MoveState.LEDGE_JUMPING:
		_current_state = MoveState.MOVING
	await grid_step_landed


func get_input_direction() -> Vector3i:
	return Vector3i.ZERO


func notify_grid_step_landed(ground: Vector3i) -> void:
	grid_step_landed.emit(ground)
	_on_animation_grid_step_landed(ground)


func key_hold_ready() -> bool:
	return true


## Override in a subclass to hook turn animation start (in addition to `turn_started` if you use signals).
func _on_animation_turn_started(_facing: Vector3i) -> void:
	pass


## Override in a subclass to hook the turn state finishing and returning to idle.
func _on_animation_turn_finished() -> void:
	pass


## Override in a subclass when a grid-walk lerp to the next cell begins.
func _on_animation_move_step_started(_step: Vector3i, _to_cell: Vector3i) -> void:
	pass


## Called when a walk segment lerp has finished (player lands on a new cell).
func _on_animation_grid_step_landed(_ground: Vector3i) -> void:
	pass


## When movement stops and returns to idle without starting a new turn in the same frame.
func _on_animation_walk_reached_idle() -> void:
	pass


func _start_turning(dir: Vector3i) -> void:
	if dir == Vector3i.ZERO:
		return
	_set_walk_anim_speed(false)
	anim_helper.apply_blends_for_grid_direction(dir)
	var sm := anim_helper.state_machine_playback()
	if sm:
		sm.start(&"Turn")
	_facing_grid = dir
	_turn_ray_in(dir)
	_current_state = MoveState.TURNING
	_turn_timer = 0.0
	turn_started.emit(dir)
	_on_animation_turn_started(dir)


func _turn_ray_in(direction: Vector3i) -> void:
	ray_cast_3d.force_raycast_update()
	ray_cast_3d.target_position = Vector3(direction)


func _finish_turn() -> void:
	_set_walk_anim_speed(false)
	anim_helper.apply_direction_blends(anim_helper.blend_for_facing(_facing_grid))
	var sm := anim_helper.state_machine_playback()
	if sm:
		sm.start(&"Idle")
	_current_state = MoveState.IDLE
	turn_finished.emit()
	_on_animation_turn_finished()


func _finish_walk_to_idle() -> void:
	_set_walk_anim_speed(false)
	anim_helper.apply_direction_blends(anim_helper.blend_for_facing(_facing_grid))
	var sm := anim_helper.state_machine_playback()
	if sm:
		sm.start(&"Idle")
	_current_state = MoveState.IDLE
	walk_reached_idle.emit()
	_on_animation_walk_reached_idle()


func _process_idle_state() -> void:
	var input_dir := get_input_direction()
	if input_dir == Vector3i.ZERO:
		return
	if input_dir != _facing_grid:
		_start_turning(input_dir)
		return
	if _try_begin_slide(input_dir):
		if _current_state == MoveState.LEDGE_JUMPING:
			return
		_current_state = MoveState.MOVING


func _process_turning_state(delta: float) -> void:
	_turn_timer += delta
	var input_dir := get_input_direction()
	var should_move: bool = input_dir == _facing_grid \
	and key_hold_ready() \
	and input_dir != Vector3i.ZERO
	if should_move and _try_begin_slide(input_dir):
		if _current_state == MoveState.LEDGE_JUMPING:
			return
		_current_state = MoveState.MOVING
		return
	if _turn_timer >= TURN_DURATION:
		_finish_turn()


func _process_moving_state(delta: float) -> void:
	if _moving:
		_move_progress += walk_speed * delta
		if _move_progress < 1.0:
			global_position = _tile_start_world.lerp(_tile_target_world, _move_progress)
			return
		global_position = _tile_target_world
		_move_progress = 0.0
		var ground := helper.get_ground_cell(global_position, grid_map, HEIGHT_ADJUSTMENT)
		notify_grid_step_landed(ground)
		_moving = false

	var input_dir := get_input_direction()
	if input_dir == Vector3i.ZERO:
		_finish_walk_to_idle()
		return
	if input_dir != _facing_grid:
		_finish_walk_to_idle()
		_start_turning(input_dir)
		return
	if not _try_begin_slide(input_dir):
		_finish_walk_to_idle()


func _process_ledge_jumping_state(delta: float) -> void:
	_move_progress += ledge_jump_speed * delta
	if _move_progress < 1.0:
		var flat_pos := _tile_start_world.lerp(_tile_target_world, _move_progress)
		var arc := sin(_move_progress * PI) * ledge_jump_height
		global_position = flat_pos + Vector3.UP * arc
		return
	global_position = _tile_target_world
	_move_progress = 0.0
	_moving = false
	var ground := helper.get_ground_cell(global_position, grid_map, HEIGHT_ADJUSTMENT)
	notify_grid_step_landed(ground)
	_finish_walk_to_idle()


func _process_movement_state(delta: float) -> void:
	match _current_state:
		MoveState.IDLE:
			_process_idle_state()
		MoveState.TURNING:
			_process_turning_state(delta)
		MoveState.MOVING:
			_process_moving_state(delta)
		MoveState.LEDGE_JUMPING:
			_process_ledge_jumping_state(delta)


func _try_begin_slide(direction: Vector3i) -> bool:
	_turn_ray_in(direction)
	ray_cast_3d.force_raycast_update()
	if not can_move_in():
		return false
	if grid_map == null:
		return false
	var ground := helper.get_ground_cell(global_position, grid_map, HEIGHT_ADJUSTMENT)
	var edges: Array = grid_map.graph.get(ground, [])
	if not edges:
		return false
	for edge: GraphEdge in edges:
		if edge.step == direction:
			match edge.move_kind:
				GraphEdge.MoveKind.LEDGE_JUMP:
					_begin_ledge_jump(edge)
				_:
					_begin_slide(edge)
			return true
	return false


func _begin_slide(edge: GraphEdge) -> void:
	_tile_start_world = global_position
	_tile_target_world = Vector3(edge.to_cell) + HEIGHT_ADJUSTMENT
	_move_progress = 0.0
	_moving = true
	_ensure_walk_playing()
	_set_walk_anim_speed(true)
	move_step_started.emit(edge.step, edge.to_cell)
	_on_animation_move_step_started(edge.step, edge.to_cell)


func _begin_ledge_jump(edge: GraphEdge) -> void:
	_tile_start_world = global_position
	_tile_target_world = Vector3(edge.to_cell) + HEIGHT_ADJUSTMENT
	_move_progress = 0.0
	_moving = true
	_current_state = MoveState.LEDGE_JUMPING
	anim_helper.apply_blends_for_grid_direction(edge.step)
	_ensure_jump_playing()
	_play_shadow()


func _ensure_jump_playing() -> void:
	var sm := anim_helper.state_machine_playback()
	if sm == null:
		return
	if sm.get_current_node() != &"Jump":
		sm.start(&"Jump")


func _ensure_walk_playing() -> void:
	var sm := anim_helper.state_machine_playback()
	if sm == null:
		return
	if sm.get_current_node() != &"Walk":
		sm.start(&"Walk")


func _set_walk_anim_speed(walking: bool) -> void:
	if animation_player == null:
		return
	if walking:
		animation_player.speed_scale = WALK_ANIM_LENGTH_SEC * walk_speed
	else:
		animation_player.speed_scale = 1.0


func _play_shadow() -> void:
	shadow.visible = true
	shadow.stop()
	shadow.frame = 0
	await get_tree().process_frame
	shadow.play()
	await shadow.animation_finished
	shadow.visible = false
