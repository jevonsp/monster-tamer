class_name Player
extends TileMover

enum TravelState { DEFAULT, SURFING, BIKING, CLIMBING }
enum SpriteState { DEFAULT, GRASS }

static var in_battle: bool = false

static var party
static var inventory
static var story_flag
static var player_info

const  TURN_DURATION := 0.1

@export var available_travel_methods: Dictionary = {
	TravelState.SURFING: false,
	TravelState.BIKING: false,
}

var travel_state: TravelState = TravelState.DEFAULT
var sprite_state: SpriteState = SpriteState.DEFAULT

var held_keys: Array = []
var key_hold_times: Dictionary = { }
var turn_timer: float = 0.0
var command_active: bool = false
var processing: bool = true
var current_map: TileMapLayer = null
var respawn_point: Vector2 = Vector2.ZERO

@onready var party_handler: Node = $PartyHandler
@onready var inventory_handler: Node = $InventoryHandler
@onready var story_flag_handler: Node = $StoryFlagHandler
@onready var player_info_handler: Node = $PlayerInfoHandler
@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	super()
	add_to_group("player")
	_connect_signals()
	set_respawn_point()
	_set_static_refs()
	party_handler.create_storage()


func _process(delta: float) -> void:
	if not processing or command_active:
		return
	update_held_keys(delta)


func _physics_process(delta: float) -> void:
	if not processing:
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


func _input(event: InputEvent) -> void:
	if not processing or command_active:
		return
	if event.is_action_pressed("yes"):
		_attempt_interaction()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("menu"):
		_open_menu()
		get_viewport().set_input_as_handled()
	
	
func _set_static_refs() -> void:
	party = party_handler
	inventory = inventory_handler
	story_flag = story_flag_handler
	player_info = player_info_handler
	player_info.player = self


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
	var tile = _get_next_tile_coords(input_dir)
	if travel_state == TravelState.SURFING and not _is_tile_water(tile):
		stop_surfing()

	return try_start_move(input_dir)


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


func start_surfing() -> void:
	travel_state = TravelState.SURFING
	get_tree().call_group("surf_object", "toggle_mode", SurfObject.State.PASSABLE)
	await walk_one_tile(facing_direction)


func stop_surfing() -> void:
	travel_state = TravelState.DEFAULT
	get_tree().call_group("surf_object", "toggle_mode", SurfObject.State.NOT_PASSABLE)


func _connect_signals() -> void:
	Battle.toggle_in_battle.connect(toggle_in_battle)
	Global.send_respawn_player.connect(_respawn)
	party_handler._connect_signals()
	inventory_handler._connect_signals()

func _clear_manual_input_buffer() -> void:
	held_keys.clear()
	key_hold_times.clear()


func _finish_commanded_movement(clear_target := true) -> void:
	command_active = false
	if clear_target:
		eventual_target_pos = global_position


func _on_walk_step_completed() -> void:
	Global.step_completed.emit(global_position)


func _attempt_interaction() -> void:
	if ray_cast_2d.is_colliding():
		if move_progress != 0.0:
			await Global.step_completed
		var collider = ray_cast_2d.get_collider()
		if collider.is_in_group("interactable") and collider.has_method("interact"):
			collider.interact(self)


func _respawn() -> void:
	global_position = respawn_point
	sync_tile_positions()
	party_handler.fully_heal_and_revive_party()


func _open_menu() -> void:
	party_handler.send_player_party()
	inventory_handler.send_player_inventory()
	if move_progress != 0.0:
		await Global.step_completed
	Ui.request_open_menu.emit()


func _get_next_tile_coords(dir: Vector2) -> Vector2i:
	var result: Vector2i = global_position + dir * Vector2(TILE_SIZE, TILE_SIZE)
	return current_map.local_to_map(result)


func _is_tile_water(tile: Vector2i) -> bool:
	return current_map.get_cell_atlas_coords(tile) == Vector2i(2, 0)


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


func enter_grass() -> void:
	sprite_state = SpriteState.GRASS
	
	
func exit_grass() -> void:
	sprite_state = SpriteState.DEFAULT
