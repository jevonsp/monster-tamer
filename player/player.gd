class_name Player
extends TileMover

enum TravelState { DEFAULT, SURFING, BIKING, CLIMBING }

static var in_battle: bool = false

static var party: PartyHandler
static var inventory: InventoryHandler
static var story_flags: StoryFlagHandler
static var travel: TravelHandler
static var info: Info

const  TURN_DURATION := 0.1

var travel_state: TravelState = TravelState.DEFAULT

var held_keys: Array = []
var key_hold_times: Dictionary = { }
var turn_timer: float = 0.0
var command_active: bool = false
var processing: bool = true
var respawn_point: Vector2 = Vector2.ZERO

var _movement_lock_depth: int = 0
var _grass_overlap_depth: int = 0
var _ladder_zone_overlap_depth: int = 0

@onready var party_handler: Node = $PartyHandler
@onready var inventory_handler: Node = $InventoryHandler
@onready var story_flag_handler: Node = $StoryFlagHandler
@onready var player_info_handler: Node = $PlayerInfoHandler
@onready var travel_handler: Node = $TravelHandler
@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	super()
	add_to_group("player")
	_set_static_refs()
	_connect_signals()
	if respawn_point == Vector2.ZERO:
		set_respawn_point()
	party_handler.create_storage()
	facing_direction = Vector2.DOWN


func _process(delta: float) -> void:
	update_held_keys(delta)


func _physics_process(delta: float) -> void:
	if not processing or is_movement_locked():
		return

	match current_state:
		MoveState.IDLE:
			if not command_active:
				process_idle_state()
		MoveState.TURNING:
			process_turning_state(delta)
		MoveState.MOVING:
			if command_active:
				animate_move(delta)
			else:
				process_walking_state(delta)
		MoveState.JUMPING:
			pass


func _input(event: InputEvent) -> void:
	if command_active:
		if event.is_action_pressed("menu"):
			get_viewport().set_input_as_handled()
		return
	if not processing:
		if event.is_action_pressed("menu") and not _text_entry_is_using_menu():
			get_viewport().set_input_as_handled()
		return
	if is_movement_locked():
		return
	if event.is_action_pressed("yes"):
		_attempt_interaction()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("menu"):
		_open_menu()
		get_viewport().set_input_as_handled()
	
	
func _text_entry_is_using_menu() -> bool:
	var te: Node = get_tree().get_first_node_in_group("text_entry_root")
	if te == null or not is_instance_valid(te):
		return false
	return te.visible and te.get("processing") == true


func _set_static_refs() -> void:
	party = party_handler
	inventory = inventory_handler
	story_flags = story_flag_handler
	info = player_info_handler
	info.player = self
	travel = travel_handler


func update_held_keys(delta: float) -> void:
	var directions = ["up", "down", "right", "left"]

	for dir in directions:
		if Input.is_action_just_pressed(dir):
			held_keys.push_back(dir)
			key_hold_times[dir] = 0.0
		elif Input.is_action_just_released(dir):
			held_keys.erase(dir)
			key_hold_times.erase(dir)
		elif Input.is_action_pressed(dir) and dir in key_hold_times:
			key_hold_times[dir] += delta
			
	if _should_suppress_vertical_input():
		for key in ["up", "down"]:
			held_keys.erase(key)
			key_hold_times.erase(key)


func _should_suppress_vertical_input() -> bool:
	return travel.is_sidescrolling and travel_state != TravelState.CLIMBING



func process_idle_state() -> void:
	var input_dir = get_input_direction()

	if input_dir == Vector2.ZERO:
		return

	if input_dir != facing_direction:
		start_turning(input_dir)
		return

	can_move_in(input_dir)


func process_turning_state(delta: float) -> void:
	turn_timer += delta

	var input_dir = get_input_direction()
	var should_move = input_dir == facing_direction \
	and not held_keys.is_empty() \
	and key_hold_times.get(held_keys.back(), 0.0) >= TURN_DURATION
	if not command_active and should_move and can_move_in(input_dir):
		return

	if turn_timer >= TURN_DURATION:
		_finish_turn()


func process_walking_state(delta: float) -> void:
	if not advance_move(delta):
		return

	Global.step_completed.emit(global_position)

	var input_dir = get_input_direction()
	if input_dir == Vector2.ZERO:
		finish_move_to_idle()
		return

	if input_dir != facing_direction:
		finish_move_to_idle()
		start_turning(input_dir)
		return

	if not can_move_in(input_dir):
		finish_move_to_idle()


func start_turning(new_facing_direction: Vector2) -> void:
	_begin_turn(new_facing_direction)
	turn_timer = 0.0
	Global.step_completed.emit(global_position)
	if command_active:
		await finished_turn


func can_move_in(input_dir: Vector2) -> bool:
	var tile = get_next_tile_coords(input_dir)
	var current_map = get_current_map()
	
	if travel_state == TravelState.SURFING and not TileChecker.is_tile_water(tile, current_map):
		travel_handler.stop_surfing()

	var started := try_start_move(input_dir)
	if not started:
		_bump()
	return started


func _bump() -> void:
	var collider: Object = get_interaction_ray_collider()
	if collider == null:
		return
	var target := _resolve_interactable(collider)
	if target is StaticObject:
		target.interact(self)


func get_input_direction() -> Vector2:
	if held_keys.is_empty():
		return Vector2.ZERO

	var direction_map = {
		"up": Vector2.UP,
		"down": Vector2.DOWN,
		"left": Vector2.LEFT,
		"right": Vector2.RIGHT,
	}

	return direction_map.get(held_keys.back(), Vector2.ZERO)


func walk_list_tiles(tiles: Array[Vector2]) -> void:
	_clear_manual_input_buffer()
	command_active = true
	await super.walk_list_tiles(tiles)
	_finish_commanded_movement()


func walk_list_dirs(dirs: Array[Vector2]) -> void:
	_clear_manual_input_buffer()
	command_active = true
	await super.walk_list_dirs(dirs)
	_finish_commanded_movement()


func walk_to_tile(pos: Vector2) -> void:
	_clear_manual_input_buffer()
	command_active = true
	await super.walk_to_tile(pos)
	if current_state != MoveState.IDLE:
		await finished_walk_segment
	_finish_commanded_movement()


func walk_one_tile(dir: Vector2) -> void:
	_clear_manual_input_buffer()
	command_active = true
	await super.walk_one_tile(dir)
	if current_state != MoveState.IDLE:
		await finished_walk_segment
	_finish_commanded_movement()


func clear_inputs() -> void:
	_clear_manual_input_buffer()
	command_active = false
	eventual_target_pos = global_position
	current_state = MoveState.IDLE
	move_progress = 0.0
	animation_tree.set("parameters/Idle/blend_position", _get_idle_blend_position())
	anim_state.travel("Idle")


func toggle_in_battle() -> void:
	in_battle = not in_battle
	if not in_battle:
		for monster in party_handler.party:
			monster.was_active_in_battle = false


func set_respawn_point() -> void:
	respawn_point = global_position


func _connect_signals() -> void:
	Battle.toggle_in_battle.connect(toggle_in_battle)
	Global.send_respawn_player.connect(_respawn)
	party_handler._connect_signals()
	inventory_handler._connect_signals()
	player_info_handler._connect_signals()
	travel._connect_signals()


func _clear_manual_input_buffer() -> void:
	held_keys.clear()
	key_hold_times.clear()


func _pump_manual_idle_if_ready() -> void:
	if not processing:
		return
	if command_active:
		return
	if is_movement_locked():
		return
	if current_state != MoveState.IDLE:
		return
	process_idle_state()


func _finish_commanded_movement(clear_target := true) -> void:
	command_active = false
	if clear_target:
		eventual_target_pos = global_position
	_pump_manual_idle_if_ready()


func is_movement_locked() -> bool:
	return _movement_lock_depth > 0

func notify_ladder_zone_entered() -> void:
	_ladder_zone_overlap_depth += 1
	travel_state = TravelState.CLIMBING
	
func notify_ladder_zone_exited() -> void:
	_ladder_zone_overlap_depth = maxi(0, _ladder_zone_overlap_depth - 1)
	if _ladder_zone_overlap_depth == 0:
		travel_state = TravelState.DEFAULT



func grass_overlap_enter() -> void:
	_grass_overlap_depth += 1
	if _grass_overlap_depth == 1:
		bottom_sprite_2d.visible = false
		top_sprite_2d.z_index = 1


func grass_overlap_exit() -> void:
	_grass_overlap_depth = maxi(0, _grass_overlap_depth - 1)
	if _grass_overlap_depth == 0:
		bottom_sprite_2d.visible = true
		top_sprite_2d.z_index = 0


func _set_movement_locked(locked: bool) -> void:
	if locked:
		_movement_lock_depth += 1
	else:
		_movement_lock_depth = maxi(0, _movement_lock_depth - 1)
		if _movement_lock_depth == 0:
			_pump_manual_idle_if_ready()


func _should_continue_path_after_lock() -> bool:
	return command_active and super._should_continue_path_after_lock()


func _on_walk_step_completed() -> void:
	Global.step_completed.emit(global_position)


func _attempt_interaction() -> void:
	var collider: Object = get_interaction_ray_collider()
	if collider == null:
		return
	if move_progress != 0.0:
		await Global.step_completed
		collider = get_interaction_ray_collider()
		if collider == null:
			return
	var target := _resolve_interactable(collider)
	if target:
		target.interact(self)


func _resolve_interactable(collider: Object) -> Node:
	var n: Node = collider as Node
	while n:
		if n.is_in_group("interactable") and n.has_method("interact"):
			return n
		n = n.get_parent()
	return null


func _respawn() -> void:
	if Options.is_nuzlocke():
		await _lose()
		return
	global_position = respawn_point
	sync_tile_positions()
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


func _open_menu() -> void:
	party_handler.send_player_party()
	inventory_handler.send_player_inventory()
	if move_progress != 0.0:
		await Global.step_completed
	Ui.request_open_menu.emit()


func _get_walk_speed() -> float:
	return 5.0


func _blend_for_cardinal_direction(dir: Vector2) -> Vector2:
	if travel_state != TravelState.CLIMBING:
		return dir
	if dir.y != 0:
		return Vector2.UP
	return dir


func _get_idle_blend_position() -> Vector2:
	if travel_state != TravelState.CLIMBING:
		return facing_direction
	if facing_direction.x != 0:
		return facing_direction
	if is_direction_blocked(Vector2.DOWN):
		return Vector2.DOWN
	return Vector2.UP
