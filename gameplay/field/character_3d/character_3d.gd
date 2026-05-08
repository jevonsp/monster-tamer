class_name Character3D
extends Area3D

signal turn_started(facing: Vector3i)
signal turn_finished
signal move_step_started(step: Vector3i, to_cell: Vector3i)
signal grid_step_landed(ground: Vector3i)
signal walk_reached_idle

enum MoveState { IDLE, TURNING, MOVING, SLIDING, LEDGE_JUMPING, CLIMBING }

const TURN_DURATION := 0.1
const WALK_ANIM_LENGTH_SEC := 0.8
const CLIMB_ANIM_LENGTH_SEC := 0.8
const MOVE_SPEED := 5.0
const STAIR_SPEED := 2.5
const HEIGHT_ADJUSTMENT := Vector3(0, 2, 0)
const SIDE_SCROLLING_HEIGHT_ADJUSTMENT := HEIGHT_ADJUSTMENT + Vector3(0, 0, -0.3)

@export var ray_cast_3d: RayCast3D
@export var walk_speed := MOVE_SPEED
@export var ledge_jump_speed := 2.0
@export var ledge_jump_height := 1.0
@export var facing_grid: Vector3i = Vector3i(0, 0, 1)

var walk_speed_modifiers := 1.0
var anim_helper := AnimationHelper.new()
var movement_helper := MovementHelper.new()
var grid_map: CustomGridMap
var _current_state: MoveState = MoveState.IDLE
var _turn_timer: float = 0.0
var _moving := false
var _tile_start_world: Vector3
var _tile_target_world: Vector3
var _move_progress: float = 0.0
var _active_edge: GraphEdge

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var shadow: AnimatedSprite3D = $BottomSprite3D/Shadow
@onready var emote: Emote = $TopSprite3D/Emote


func _ready() -> void:
	if shadow.visible:
		shadow.visible = false
	anim_helper.refresh_facing_blends(facing_grid, self)


func _physics_process(delta: float) -> void:
	if grid_map == null:
		return
	_process_movement_state(delta)


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
	await walk_path([facing_grid])


func turn_to_direction(direction: Vector3i) -> void:
	if direction == Vector3i.ZERO or direction == facing_grid:
		return
	await _await_scripted_idle()
	if direction == facing_grid:
		return
	_start_turning(direction)
	await turn_finished


func walk_path(directions: Array[Vector3i]) -> bool:
	if directions.is_empty():
		return true
	if grid_map == null:
		return false
	await _await_scripted_idle()
	for direction: Vector3i in directions:
		if direction == Vector3i.ZERO:
			continue
		if direction != facing_grid:
			await turn_to_direction(direction)
		if not _try_start_move(direction):
			return false
		await grid_step_landed
	return true


func look_directions(directions: Array[Vector3i]) -> bool:
	if directions.is_empty():
		return true
	if grid_map == null:
		return false
	await _await_scripted_idle()
	for direction: Vector3i in directions:
		if direction == Vector3i.ZERO:
			continue
		if direction != facing_grid:
			await turn_to_direction(direction)
			await get_tree().create_timer(0.25).timeout
	return true


func get_input_direction() -> Vector3i:
	return Vector3i.ZERO


func get_height_adjustment() -> Vector3:
	return HEIGHT_ADJUSTMENT


func cell_to_world(cell: Vector3i) -> Vector3:
	return Vector3(cell) + get_height_adjustment()


func get_ground_cell_at(world_position: Vector3) -> Vector3i:
	return movement_helper.get_ground_cell(world_position, grid_map, get_height_adjustment())


func get_current_ground_cell() -> Vector3i:
	return get_ground_cell_at(global_position)


func notify_grid_step_landed(ground: Vector3i) -> void:
	grid_step_landed.emit(ground)
	_on_move_edge_landed(_active_edge, ground)
	_active_edge = null
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


## Called when a slide state begins on the first step onto ice.
func _on_animation_slide_started(_step: Vector3i, _to_cell: Vector3i) -> void:
	pass


## Called when a slide continues automatically to another ice step.
func _on_animation_slide_continued(_step: Vector3i, _to_cell: Vector3i) -> void:
	pass


## Called when a slide sequence resolves and control returns to idle.
func _on_animation_slide_finished(_ground: Vector3i) -> void:
	pass


## When movement stops and returns to idle without starting a new turn in the same frame.
func _on_animation_walk_reached_idle() -> void:
	pass


func _on_move_edge_landed(_edge: GraphEdge, _ground: Vector3i) -> void:
	pass


func _await_scripted_idle() -> void:
	if _current_state == MoveState.IDLE and not _moving:
		return
	if _current_state == MoveState.TURNING:
		await turn_finished
		return
	await walk_reached_idle


func _can_traverse_edge(_edge: GraphEdge, _from_cell: Vector3i) -> bool:
	return true


func _start_turning(dir: Vector3i) -> void:
	if dir == Vector3i.ZERO:
		return
	_set_walk_anim_speed(false)
	anim_helper.apply_blends_for_grid_direction(dir)
	var sm := anim_helper.state_machine_playback()
	if sm:
		sm.start(&"Turn")
	facing_grid = dir
	_turn_ray_in(dir)
	_current_state = MoveState.TURNING
	_turn_timer = 0.0
	turn_started.emit(dir)
	_on_animation_turn_started(dir)


func _turn_ray_in(direction: Vector3i) -> void:
	ray_cast_3d.target_position = Vector3(direction)
	ray_cast_3d.force_raycast_update()


func _finish_turn() -> void:
	_set_walk_anim_speed(false)
	anim_helper.apply_direction_blends(anim_helper.blend_for_facing(facing_grid))
	var sm := anim_helper.state_machine_playback()
	if sm:
		sm.start(&"Idle")
	_current_state = MoveState.IDLE
	turn_finished.emit()
	_on_animation_turn_finished()


func _finish_walk_to_idle() -> void:
	var finished_slide := _current_state == MoveState.SLIDING
	var ground := Vector3i.ZERO
	if grid_map != null:
		ground = get_current_ground_cell()
	_set_walk_anim_speed(false)
	anim_helper.apply_direction_blends(anim_helper.blend_for_facing(facing_grid))
	var sm := anim_helper.state_machine_playback()
	if sm:
		sm.start(&"Idle")
	_current_state = MoveState.IDLE
	walk_reached_idle.emit()
	if finished_slide:
		_on_animation_slide_finished(ground)
	_on_animation_walk_reached_idle()


func _process_idle_state() -> void:
	var input_dir := get_input_direction()
	if input_dir == Vector3i.ZERO:
		return
	if input_dir != facing_grid:
		_start_turning(input_dir)
		return
	_try_start_move(input_dir)


func _process_turning_state(delta: float) -> void:
	_turn_timer += delta
	var input_dir := get_input_direction()
	var should_move: bool = input_dir == facing_grid \
	and key_hold_ready() \
	and input_dir != Vector3i.ZERO
	if should_move and _try_start_move(input_dir):
		return
	if _turn_timer >= TURN_DURATION:
		_finish_turn()


func _process_moving_state(delta: float) -> void:
	if _moving:
		if _advance_step_motion(delta):
			return
		if _moving:
			return

	var input_dir := get_input_direction()
	if input_dir == Vector3i.ZERO:
		_finish_walk_to_idle()
		return
	if input_dir != facing_grid:
		_finish_walk_to_idle()
		_start_turning(input_dir)
		return
	if not _try_start_move(input_dir):
		_finish_walk_to_idle()


func _process_sliding_state(delta: float) -> void:
	if _moving:
		_move_progress += walk_speed * delta
		if _move_progress < 1.0:
			global_position = _tile_start_world.lerp(_tile_target_world, _move_progress)
			return
		var landed_edge := _active_edge
		global_position = _tile_target_world
		_move_progress = 0.0
		_moving = false
		var ground := get_current_ground_cell()
		notify_grid_step_landed(ground)
		var next_edge := _get_sliding_continuation_edge(ground, landed_edge)
		if next_edge != null:
			_begin_slide_step(next_edge, true)
			return

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
	var ground := get_current_ground_cell()
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
		MoveState.CLIMBING:
			_process_climbing_state(delta)
		MoveState.SLIDING:
			_process_sliding_state(delta)
		MoveState.LEDGE_JUMPING:
			_process_ledge_jumping_state(delta)


func _try_start_move(direction: Vector3i) -> bool:
	_turn_ray_in(direction)
	ray_cast_3d.force_raycast_update()
	if not can_move_in():
		return false
	if grid_map == null:
		return false
	var ground := get_current_ground_cell()
	var edge := _get_edge_for_direction(ground, direction)
	if edge == null:
		return false

	match edge.move_kind:
		GraphEdge.MoveKind.LEDGE_JUMP:
			_begin_ledge_jump(edge)
		GraphEdge.MoveKind.SLIDE:
			_current_state = MoveState.SLIDING
			_begin_slide_step(edge, false)
		_:
			if _current_state == MoveState.CLIMBING:
				pass
			else:
				_current_state = MoveState.MOVING
			_begin_step_move(edge)
			_set_walk_speed(direction)
	return true


func _get_edge_for_direction(from_cell: Vector3i, direction: Vector3i) -> GraphEdge:
	var edges: Array = grid_map.graph.get(from_cell, [])
	if not edges:
		return null
	for edge: GraphEdge in edges:
		if edge.step == direction and _can_traverse_edge(edge, from_cell):
			return edge
	return null


func _begin_step_move(edge: GraphEdge) -> void:
	_setup_step_move(edge)
	_ensure_walk_playing()
	_set_walk_anim_speed(true)
	move_step_started.emit(edge.step, edge.to_cell)
	_on_animation_move_step_started(edge.step, edge.to_cell)


func _setup_step_move(edge: GraphEdge) -> void:
	_tile_start_world = global_position
	_tile_target_world = cell_to_world(edge.to_cell)
	_move_progress = 0.0
	_moving = true
	_active_edge = edge


func _begin_slide_step(edge: GraphEdge, continued: bool) -> void:
	_setup_step_move(edge)
	_ensure_slide_playing()
	_set_walk_anim_speed(true)
	move_step_started.emit(edge.step, edge.to_cell)
	_on_animation_move_step_started(edge.step, edge.to_cell)
	if continued:
		_on_animation_slide_continued(edge.step, edge.to_cell)
	else:
		_on_animation_slide_started(edge.step, edge.to_cell)


func _advance_step_motion(delta: float) -> bool:
	_move_progress += walk_speed * delta
	if _move_progress < 1.0:
		global_position = _tile_start_world.lerp(_tile_target_world, _move_progress)
		return true
	global_position = _tile_target_world
	_move_progress = 0.0
	_moving = false
	var ground := get_current_ground_cell()
	notify_grid_step_landed(ground)
	return false


func _get_sliding_continuation_edge(ground: Vector3i, landed_edge: GraphEdge) -> GraphEdge:
	if landed_edge == null or landed_edge.move_kind != GraphEdge.MoveKind.SLIDE:
		return null
	if grid_map == null or not grid_map.is_ice_cell(ground):
		return null
	_turn_ray_in(landed_edge.step)
	if _slide_is_blocked_by_collider():
		return null
	var next_edge := _get_edge_for_direction(ground, landed_edge.step)
	return next_edge


func _slide_is_blocked_by_collider() -> bool:
	ray_cast_3d.force_raycast_update()
	if not ray_cast_3d.is_colliding():
		return false
	var collider: Object = ray_cast_3d.get_collider()
	if collider == null:
		return false
	if collider is CellObject:
		if "is_passable" in collider:
			return not bool(collider.get("is_passable"))
		return bool(collider.blocks_player)
	return true


func _begin_ledge_jump(edge: GraphEdge) -> void:
	_tile_start_world = global_position
	_tile_target_world = cell_to_world(edge.to_cell)
	_move_progress = 0.0
	_moving = true
	_active_edge = edge
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


func _ensure_slide_playing() -> void:
	var sm := anim_helper.state_machine_playback()
	if sm == null:
		return
	if sm.get_current_node() != &"Slide":
		sm.start(&"Slide")


func _ensure_surf_playing() -> void:
	var sm := anim_helper.state_machine_playback()
	if sm == null:
		return
	if sm.get_current_node() != &"Surf":
		sm.start(&"Surf")


func _process_climbing_state(delta: float) -> void:
	_ensure_climb_playing()
	_process_moving_state(delta)


func _ensure_climb_playing() -> void:
	var sm := anim_helper.state_machine_playback()
	if sm == null:
		return
	if sm.get_current_node() != &"Climb":
		sm.start(&"Climb")


func _set_walk_anim_speed(walking: bool) -> void:
	if animation_player == null:
		return
	if walking:
		var anim_length_sec := WALK_ANIM_LENGTH_SEC
		if _current_state == MoveState.CLIMBING:
			anim_length_sec = CLIMB_ANIM_LENGTH_SEC
		animation_player.speed_scale = anim_length_sec * walk_speed
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


func _current_anim_node_name() -> String:
	var sm := anim_helper.state_machine_playback()
	if sm == null:
		return "null"
	return str(sm.get_current_node())


func _set_walk_speed(direction: Vector3i) -> void:
	var ground := get_current_ground_cell()
	var edge := _get_edge_for_direction(ground, direction)
	var from_tile_id := grid_map.get_cell_item(ground)
	var to_tile_id := grid_map.get_cell_item(edge.to_cell)
	if from_tile_id == grid_map.TILE_DICT.STAIRS or to_tile_id == grid_map.TILE_DICT.STAIRS or _current_state == MoveState.CLIMBING:
		walk_speed = STAIR_SPEED * walk_speed_modifiers
	else:
		walk_speed = MOVE_SPEED * walk_speed_modifiers
