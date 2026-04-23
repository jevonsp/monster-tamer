class_name Character3D
extends Node3D

# Connect in the editor or call from your scripts; can also override the matching _on_animation_* virtuals in a subclass.
signal turn_started(facing: Vector3i)
signal turn_finished
signal move_step_started(step: Vector3i, to_cell: Vector3i)
signal grid_step_landed(ground: Vector3i)
signal walk_reached_idle

enum MoveState { IDLE, TURNING, MOVING }

const TURN_DURATION := 0.1
const WALK_ANIM_LENGTH_SEC := 0.8
const HEIGHT_ADJUSTMENT := Vector3(0.5, 2.3, 0.5)

@export var walk_speed := 5.0

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

@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func will_collide() -> bool:
	ray_cast_3d.force_raycast_update()
	return ray_cast_3d.is_colliding()


func can_move_in() -> bool:
	return not will_collide()


func notify_grid_step_landed(ground: Vector3i) -> void:
	grid_step_landed.emit(ground)
	_on_animation_grid_step_landed(ground)


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
			_tile_start_world = global_position
			_tile_target_world = Vector3(edge.to_cell) + HEIGHT_ADJUSTMENT
			_move_progress = 0.0
			_moving = true
			_ensure_walk_playing()
			_set_walk_anim_speed(true)
			move_step_started.emit(edge.step, edge.to_cell)
			_on_animation_move_step_started(edge.step, edge.to_cell)
			return true
	return false


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
