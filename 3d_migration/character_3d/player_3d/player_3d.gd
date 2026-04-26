class_name Player3D
extends Character3D

@export var pivot: Node3D
@export var camera_3d: Camera3D

var processing: bool = true
var held_keys: Array[String] = []
var key_hold_times: Dictionary = { }
var respawn_point: Vector3 = Vector3.ZERO
var command_active: bool = false
var in_battle: bool = false
var _asked_surfing_once: bool = false
var _bump_latched_collider_id: int = -1

@onready var party_handler: PartyHandler3D = $PartyHandler
@onready var inventory_handler: InventoryHandler3D = $InventoryHandler
@onready var story_flag_handler: StoryFlagHandler3D = $StoryFlagHandler
@onready var player_info_handler: PlayerInfo3D = $PlayerInfoHandler
@onready var travel_handler: TravelHandler3D = $TravelHandler
@onready var overlay: ColorRect = $CanvasLayer/Overlay


func _ready() -> void:
	super()
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
	_process_movement_state(delta)


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


func get_input_direction() -> Vector3i:
	if held_keys.is_empty():
		return Vector3i.ZERO
	var action: String = held_keys.back()
	return _camera_relative_cardinal_for_action(action)


func key_hold_ready() -> bool:
	return not held_keys.is_empty() \
	and key_hold_times.get(held_keys.back(), 0.0) >= TURN_DURATION


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
	if GameOptions.is_nuzlocke():
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


func _on_animation_grid_step_landed(ground: Vector3i) -> void:
	PlayerContext3D.walk_segmented_completed.emit(ground)


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


func _attempt_interaction() -> void:
	if _move_progress != 0.0:
		return

	var collider: Object = _get_interaction_ray_collider()
	if collider:
		collider.interact(self)
		return
	_try_start_surf()


func _get_interaction_ray_collider() -> Object:
	if ray_cast_3d == null:
		return null
	ray_cast_3d.force_raycast_update()
	return ray_cast_3d.get_collider() if ray_cast_3d.is_colliding() else null


func _try_start_move(direction: Vector3i) -> bool:
	_turn_ray_in(direction)
	ray_cast_3d.force_raycast_update()
	var started = can_move_in()
	if not started:
		_bump()
		return false
	_bump_latched_collider_id = -1
	if grid_map == null:
		return false
	var ground := helper.get_ground_cell(global_position, grid_map, HEIGHT_ADJUSTMENT)
	var edge := _get_edge_for_direction(ground, direction)
	if edge == null:
		var blocked_edge := _get_edge_for_direction_ignoring_travel_state(ground, direction)
		if _should_attempt_surf(blocked_edge, ground):
			_try_start_surf(direction)
		return false
	match edge.move_kind:
		GraphEdge.MoveKind.LEDGE_JUMP:
			_begin_ledge_jump(edge)
		GraphEdge.MoveKind.SLIDE:
			_current_state = MoveState.SLIDING
			_begin_slide_step(edge, false)
		_:
			_current_state = MoveState.MOVING
			_begin_step_move(edge)
	return true


func _can_traverse_edge(edge: GraphEdge, from_cell: Vector3i) -> bool:
	if edge.move_kind != GraphEdge.MoveKind.SURF:
		return true
	if travel_handler == null or grid_map == null:
		return false
	if travel_handler.is_surfing():
		return true
	return not grid_map.is_land_cell(from_cell)


func _on_move_edge_landed(edge: GraphEdge, ground: Vector3i) -> void:
	if edge == null or edge.move_kind != GraphEdge.MoveKind.SURF:
		return
	if travel_handler == null or grid_map == null:
		return
	if travel_handler.is_surfing() and grid_map.is_land_cell(ground):
		travel_handler.stop_surf()


func _should_attempt_surf(edge: GraphEdge, from_cell: Vector3i) -> bool:
	if edge == null:
		return false
	if travel_handler == null:
		return false
	return travel_handler.can_start_surf(edge, from_cell)


func _try_start_surf(direction: Vector3i = _facing_grid) -> bool:
	if grid_map == null or travel_handler == null:
		return false
	var ground := helper.get_ground_cell(global_position, grid_map, HEIGHT_ADJUSTMENT)
	var edge := _get_edge_for_direction_ignoring_travel_state(ground, direction)
	if not _should_attempt_surf(edge, ground):
		return false
	var ta: Array[String]
	if not FieldCapability._can_surf():
		ta = ["If you had a monster that could surf, you could sail the seas!"]
		Ui.send_text_box.emit(null, ta, true, false, false)
		await Ui.text_box_complete
		return false
	if not _asked_surfing_once:
		ta = ["Do you want to start surfing?"]
		Ui.send_text_box.emit(null, ta, false, true, false)
		var answer = await Ui.answer_given
		if not answer:
			return false
	_asked_surfing_once = true
	travel_handler.start_surf()
	var started := _try_start_move(direction)
	if not started:
		travel_handler.stop_surf()
		return false
	return true


func _get_edge_for_direction_ignoring_travel_state(from_cell: Vector3i, direction: Vector3i) -> GraphEdge:
	if grid_map == null:
		return null
	var edges: Array = grid_map.graph.get(from_cell, [])
	if not edges:
		return null
	for edge: GraphEdge in edges:
		if edge.step == direction:
			return edge
	return null


func _bump() -> void:
	_attempt_interaction()


func _toggle_player(value: bool) -> void:
	processing = value


func _open_menu() -> void:
	party_handler.send_player_party()
	inventory_handler.send_player_inventory()
	if _move_progress != 0.0:
		await PlayerContext3D.walk_segmented_completed
	Ui.request_open_menu.emit()
