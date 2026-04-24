class_name Player3D
extends Character3D

enum TravelState { DEFAULT, SURFING, BIKING, CLIMBING }

@export var pivot: Node3D
@export var camera_3d: Camera3D

var processing: bool = true
var held_keys: Array[String] = []
var key_hold_times: Dictionary = { }
var travel_state: TravelState = TravelState.DEFAULT
var respawn_point: Vector3 = Vector3.ZERO
var command_active: bool = false
var in_battle: bool = false

@onready var party_handler: PartyHandler3D = $PartyHandler
@onready var inventory_handler: InventoryHandler3D = $InventoryHandler
@onready var story_flag_handler: StoryFlagHandler3D = $StoryFlagHandler
@onready var player_info_handler: PlayerInfo3D = $PlayerInfoHandler
@onready var travel_handler: TravelHandler3D = $TravelHandler


func _ready() -> void:
	add_to_group("player")
	setup()


func _process(delta: float) -> void:
	if not processing or camera_3d == null:
		return
	_update_held_keys(delta)
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
	if command_active:
		if event.is_action_pressed("menu"):
			get_viewport().set_input_as_handled()
		return
	if camera_3d == null or (camera_3d.has_method("is_pivot_orbiting") and camera_3d.is_pivot_orbiting()) or pivot == null:
		return
	if _current_state != MoveState.IDLE:
		return
	if event.is_action_pressed("yes"):
		_attempt_interaction()
		get_viewport().set_input_as_handled()
	if not processing:
		if event.is_action_pressed("menu") and not _text_entry_is_using_menu():
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("menu"):
		_open_menu()
		get_viewport().set_input_as_handled()


func setup() -> void:
	setup_helpers()
	setup_player_context()
	_setup_handlers_3d()


func setup_helpers() -> void:
	animation_tree.anim_player = NodePath("../AnimationPlayer")
	animation_tree.active = true
	animation_tree.advance(0.0)
	anim_helper.animation_tree = animation_tree
	anim_helper.camera_3d = camera_3d
	if camera_3d:
		camera_3d.pivot = pivot
		camera_3d.rotation_midpoint_reached.connect(_on_camera_rotation_finished)
		camera_3d.rotation_finished.connect(_on_camera_rotation_finished)
	anim_helper.call_deferred("refresh_facing_blends", _facing_grid, self)


func setup_player_context() -> void:
	PlayerContext3D.player = self
	PlayerContext3D.camera_3d = camera_3d
	if not PlayerContext3D.toggle_player.is_connected(_toggle_player):
		PlayerContext3D.toggle_player.connect(_toggle_player)
	PlayerContext3D.party_handler = party_handler
	PlayerContext3D.inventory_handler = inventory_handler
	PlayerContext3D.story_flag_handler = story_flag_handler
	PlayerContext3D.travel_handler = travel_handler
	PlayerContext3D.player_info_handler = player_info_handler


func set_respawn_point() -> void:
	respawn_point = global_position
	player_info_handler.respawn_point = Vector2(respawn_point.x, respawn_point.z)


func toggle_in_battle() -> void:
	in_battle = not in_battle
	if not in_battle:
		for monster in party_handler.party:
			monster.was_active_in_battle = false


func walk_one_step_along_facing() -> void:
	if grid_map == null:
		return
	if _current_state != MoveState.IDLE or _moving:
		return
	if not _try_begin_slide(_facing_grid):
		return
	_current_state = MoveState.MOVING
	await grid_step_landed


func get_input_direction() -> Vector3i:
	if held_keys.is_empty():
		return Vector3i.ZERO
	var action: String = held_keys.back()
	return _camera_relative_cardinal_for_action(action)


func clear_inputs() -> void:
	held_keys.clear()
	key_hold_times.clear()


func set_movement_locked(value: bool) -> void:
	clear_inputs()
	if value:
		processing = false
	else:
		processing = true


func _text_entry_is_using_menu() -> bool:
	var te: Node = get_tree().get_first_node_in_group("text_entry_root")
	if te == null or not is_instance_valid(te):
		return false
	return te.visible and te.get("processing") == true


func _setup_handlers_3d() -> void:
	player_info_handler.player = self
	if not player_info_handler.player_info.is_empty():
		player_info_handler.update_info()
	if respawn_point == Vector3.ZERO:
		set_respawn_point()
	party_handler.create_storage()
	party_handler._connect_signals()
	inventory_handler._connect_signals()
	player_info_handler._connect_signals()
	travel_handler._connect_signals()
	if not Battle.toggle_in_battle.is_connected(toggle_in_battle):
		Battle.toggle_in_battle.connect(toggle_in_battle)
	if not Global.send_respawn_player.is_connected(_respawn):
		Global.send_respawn_player.connect(_respawn)


func _respawn() -> void:
	if Options.is_nuzlocke():
		await _lose()
		return
	global_position = respawn_point
	party_handler.fully_heal_and_revive_party()


func _lose() -> void:
	var ta: Array[String] = [
		"You have ran out of usable Monsters while in Nuzlocke mode.",
		"You will be returned to the title screen.",
		"You can permanently turn off Nuzlocke mode at any time in the options menu.",
	]
	Ui.send_text_box.emit(null, ta, false, false, false)
	await Ui.text_box_complete

	SaverLoader.switch_to_title()


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
	if not collider:
		return
	collider.interact(self)


func _get_interaction_ray_collider() -> Object:
	if ray_cast_3d == null:
		return null
	ray_cast_3d.force_raycast_update()
	return ray_cast_3d.get_collider() if ray_cast_3d.is_colliding() else null


func _toggle_player(value: bool) -> void:
	processing = value


func _open_menu() -> void:
	party_handler.send_player_party()
	inventory_handler.send_player_inventory()
	if _move_progress != 0.0:
		await PlayerContext3D.walk_segmented_completed
	Ui.request_open_menu.emit()
