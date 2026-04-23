class_name Player3D
extends Character3D

@export var pivot: Node3D
@export var camera_3d: Camera3D

var processing: bool = true
var held_keys: Array[String] = []
var key_hold_times: Dictionary = { }


func _ready() -> void:
	setup()


func _process(delta: float) -> void:
	if not processing or camera_3d == null:
		return
	_update_held_keys(delta)
	# Recompute blend space every frame while the pivot (camera yaw) is tweening so 8-way sprites follow the view.
	if camera_3d.has_method("is_pivot_orbiting") and camera_3d.is_pivot_orbiting():
		anim_helper.refresh_facing_blends(_facing_grid, self)
	if Input.is_action_pressed("right_stick_right"):
		camera_3d._rotate_camera(1)
	elif Input.is_action_pressed("right_stick_left"):
		camera_3d._rotate_camera(-1)


func _physics_process(delta: float) -> void:
	if not processing:
		return
	if grid_map == null:
		return
	if pivot == null or camera_3d == null or (camera_3d.has_method("is_pivot_orbiting") and camera_3d.is_pivot_orbiting()):
		return
	match _current_state:
		MoveState.IDLE:
			_process_idle_state()
		MoveState.TURNING:
			_process_turning_state(delta)
		MoveState.MOVING:
			_process_moving_state(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not processing or grid_map == null:
		return
	if camera_3d == null or (camera_3d.has_method("is_pivot_orbiting") and camera_3d.is_pivot_orbiting()) or pivot == null:
		return
	if _current_state != MoveState.IDLE:
		return
	if event.is_action_pressed("yes"):
		_attempt_interaction()


func setup() -> void:
	# Path is from this AnimationTree node: sibling AnimationPlayer is ../AnimationPlayer (not a child).
	animation_tree.anim_player = NodePath("../AnimationPlayer")
	animation_tree.active = true
	animation_tree.advance(0.0)
	anim_helper.animation_tree = animation_tree
	anim_helper.camera_3d = camera_3d
	if camera_3d:
		camera_3d.pivot = pivot
		camera_3d.rotation_midpoint_reached.connect(_on_camera_rotation_finished)
		camera_3d.rotation_finished.connect(_on_camera_rotation_finished)
	PlayerContext3D.player = self
	PlayerContext3D.camera_3d = camera_3d
	anim_helper.call_deferred("refresh_facing_blends", _facing_grid, self)
	PlayerContext3D.toggle_player.connect(_toggle_player)


func get_input_direction() -> Vector3i:
	if held_keys.is_empty():
		return Vector3i.ZERO
	var action: String = held_keys.back()
	return _camera_relative_cardinal_for_action(action)


func _on_camera_rotation_finished() -> void:
	anim_helper.refresh_facing_blends(_facing_grid, self)


func _update_held_keys(delta: float) -> void:
	var directions: Array[String] = ["forward", "back", "left", "right", "up", "down"]
	for dir in directions:
		if Input.is_action_just_pressed(dir):
			held_keys.push_back(dir)
			key_hold_times[dir] = 0.0
		elif Input.is_action_just_released(dir):
			held_keys.erase(dir)
			key_hold_times.erase(dir)
		elif Input.is_action_pressed(dir) and dir in key_hold_times:
			key_hold_times[dir] += delta


func _camera_relative_cardinal_for_action(action: String) -> Vector3i:
	match action:
		"forward", "up":
			return _camera_relative_cardinal(Vector3.FORWARD)
		"back", "down":
			return _camera_relative_cardinal(Vector3.BACK)
		"left":
			return _camera_relative_cardinal(Vector3.LEFT)
		"right":
			return _camera_relative_cardinal(Vector3.RIGHT)
		_:
			return Vector3i.ZERO


func _camera_relative_cardinal(local_dir: Vector3) -> Vector3i:
	var world_dir := pivot.global_transform.basis * local_dir
	world_dir.y = 0.0
	if world_dir.length_squared() < 0.0001:
		return Vector3i.ZERO
	world_dir = world_dir.normalized()

	if absf(world_dir.x) >= absf(world_dir.z):
		return Vector3i(1, 0, 0) if world_dir.x > 0.0 else Vector3i(-1, 0, 0)
	else:
		return Vector3i(0, 0, 1) if world_dir.z > 0.0 else Vector3i(0, 0, -1)


func _process_idle_state() -> void:
	var input_dir := get_input_direction()
	if input_dir == Vector3i.ZERO:
		return
	if input_dir != _facing_grid:
		_start_turning(input_dir)
		return
	if _try_begin_slide(input_dir):
		_current_state = MoveState.MOVING


func _process_turning_state(delta: float) -> void:
	_turn_timer += delta
	var input_dir := get_input_direction()
	var should_move: bool = input_dir == _facing_grid \
	and not held_keys.is_empty() \
	and key_hold_times.get(held_keys.back(), 0.0) >= TURN_DURATION
	if should_move and _try_begin_slide(input_dir):
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
		PlayerContext3D.walk_segmented_completed.emit(ground)
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


func _attempt_interaction() -> void:
	if _move_progress != 0.0:
		return
	var collider: Object = _get_interaction_ray_collider()
	if collider == null:
		return
	var target := _resolve_interactable(collider)
	if target:
		processing = false
		target.interact(self)


func _get_interaction_ray_collider() -> Object:
	if ray_cast_3d == null:
		return null
	ray_cast_3d.force_raycast_update()
	return ray_cast_3d.get_collider() if ray_cast_3d.is_colliding() else null


func _resolve_interactable(collider: Object) -> Node:
	var n: Node = collider as Node
	while n:
		if n.is_in_group("interactable") and n.has_method("interact"):
			return n
		n = n.get_parent()
	return null


func _toggle_player(value: bool) -> void:
	processing = value
