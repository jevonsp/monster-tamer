extends CharacterBody2D
# State machine
enum State {IDLE, TURNING, WALKING, JUMPING}
var current_state = State.IDLE

# Facing direction
enum Direction {UP, DOWN, LEFT, RIGHT}
var facing_direction = Direction.DOWN

# Constants
const TILE_SIZE := 16.0
const WALK_SPEED := 5.0
const TURN_DURATION := 0.05

# Movement tracking
var tile_start_pos: Vector2 = Vector2.ZERO
var tile_target_pos: Vector2 = Vector2.ZERO
var move_progress: float = 0.0

# Input tracking
var held_keys: Array = []
var key_hold_times: Dictionary = {}  # Track how long each key has been held

# Turn timer
var turn_timer: float = 0.0

# Processing control
var processing: bool = true
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var anim_state = animation_tree.get("parameters/playback")

var respawn_point: Vector2
func _ready() -> void:
	add_to_group("player")
	tile_start_pos = position
	tile_target_pos = position
	
func _process(delta: float) -> void:
	update_held_keys(delta)
		
func _physics_process(delta: float) -> void:
	if not processing:
		return
	match current_state:
		State.IDLE:
			process_idle_state()
		State.TURNING:
			process_turning_state(delta)
		State.WALKING:
			process_walking_state(delta)

func _input(event: InputEvent) -> void:
	if not processing:
		return
	if event.is_action_pressed("yes"):
		attempt_interaction()

func process_idle_state() -> void:
	var input_dir = get_input_direction()
	
	if input_dir != Vector2.ZERO:
		var new_facing = direction_from_vector(input_dir)
		
		# Check if we need to turn
		if new_facing != facing_direction:
			start_turning(new_facing)
		else:
			# Already facing correct direction, try to move
			attempt_movement(input_dir)

func process_turning_state(delta: float) -> void:
	turn_timer += delta
	
	var input_dir = get_input_direction()
	if input_dir != Vector2.ZERO:
		var input_facing = direction_from_vector(input_dir)
		if input_facing == facing_direction:
			# Only start moving if the key has been held longer than turn duration
			var last_key = held_keys.back() if not held_keys.is_empty() else ""
			if last_key in key_hold_times and key_hold_times[last_key] >= TURN_DURATION:
				# Key held long enough - start moving immediately
				if attempt_movement(input_dir):
					return  # Successfully started moving
	
	if turn_timer >= TURN_DURATION:
		# Turn complete - update idle blend position to match new facing
		var blend_dir = vector_from_direction(facing_direction)
		#animation_tree.set("parameters/Idle/blend_position", blend_dir)
		
		current_state = State.IDLE
		#anim_state.travel("Idle")

func process_walking_state(delta: float) -> void:
	move_progress += WALK_SPEED * delta
	
	if move_progress >= 1.0:
		position = tile_target_pos
		move_progress = 0.0
		var input_dir = get_input_direction()
		if input_dir != Vector2.ZERO:
			var new_facing = direction_from_vector(input_dir)
			
			if new_facing != facing_direction:
				current_state = State.IDLE
				#anim_state.travel("Idle")
				start_turning(new_facing)
			else:
				if not attempt_movement(input_dir):
					current_state = State.IDLE
					#anim_state.travel("Idle")
		else:
			current_state = State.IDLE
			#anim_state.travel("Idle")
	else:
		position = tile_start_pos.lerp(tile_target_pos, move_progress)

func start_turning(new_facing: Direction) -> void:
	var blend_dir = vector_from_direction(new_facing)
	
	#animation_tree.set("parameters/Turn/blend_position", blend_dir)
	#animation_tree.set("parameters/Idle/blend_position", blend_dir)
	#animation_tree.set("parameters/Walk/blend_position", blend_dir)
	
	facing_direction = new_facing
	
	var ray_dir = vector_from_direction(new_facing)
	ray_cast_2d.target_position = ray_dir * TILE_SIZE / 2
	
	current_state = State.TURNING
	turn_timer = 0.0
	
	#anim_state.travel("Turn")

func attempt_movement(input_dir: Vector2) -> bool:
	ray_cast_2d.target_position = input_dir * TILE_SIZE / 2
	ray_cast_2d.force_raycast_update()
			
	if ray_cast_2d.is_colliding():
		var collider = ray_cast_2d.get_collider()
		
		if collider.is_in_group("ledge"):
			var facing = vector_from_direction(facing_direction)
			var allowed = vector_from_direction(collider.allowed_direction)
			if facing.dot(allowed) == -1:
				#animate_ledge()
				return true
		return false
	tile_start_pos = position
	tile_target_pos = position + (input_dir * TILE_SIZE)
	move_progress = 0.0
	current_state = State.WALKING
	
	var blend_dir = input_dir
	#animation_tree.set("parameters/Walk/blend_position", blend_dir)
	#anim_state.travel("Walk")
	return true

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

func get_input_direction() -> Vector2:
	if held_keys.is_empty():
		return Vector2.ZERO
	
	var direction_map = {
		"up": Vector2(0, -1),
		"down": Vector2(0, 1),
		"left": Vector2(-1, 0),
		"right": Vector2(1, 0)
	}
	
	var key = held_keys.back()
	return direction_map.get(key, Vector2.ZERO)
	
func clear_inputs() -> void:
	held_keys.clear()
	key_hold_times.clear()
	current_state = State.IDLE
	move_progress = 0.0
	#anim_state.travel("Idle")
	
func direction_from_vector(vec: Vector2) -> Direction:
	if vec.x < 0:
		return Direction.LEFT
	elif vec.x > 0:
		return Direction.RIGHT
	elif vec.y < 0:
		return Direction.UP
	else:
		return Direction.DOWN
		
func vector_from_direction(dir: Direction) -> Vector2:
	match dir:
		Direction.UP: return Vector2(0, -1)
		Direction.DOWN: return Vector2(0, 1)
		Direction.LEFT: return Vector2(-1, 0)
		Direction.RIGHT: return Vector2(1, 0)
	return Vector2.ZERO

func attempt_interaction() -> void:
	if ray_cast_2d.is_colliding():
		var collider = ray_cast_2d.get_collider()
		if collider.is_in_group("interactable"):
			collider.interact(self)
