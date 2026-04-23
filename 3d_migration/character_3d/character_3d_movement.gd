class_name Character3D
extends Node3D

enum MoveState { IDLE, TURNING, MOVING }

const TURN_DURATION := 0.1
const WALK_ANIM_LENGTH_SEC := 0.8
const HEIGHT_ADJUSTMENT := Vector3(0.5, 2.5, 0.5)

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


func _finish_walk_to_idle() -> void:
	_set_walk_anim_speed(false)
	anim_helper.apply_direction_blends(anim_helper.blend_for_facing(_facing_grid))
	var sm := anim_helper.state_machine_playback()
	if sm:
		sm.start(&"Idle")
	_current_state = MoveState.IDLE


func _try_begin_slide(direction: Vector3i) -> bool:
	_turn_ray_in(direction)
	ray_cast_3d.force_raycast_update()
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
