extends CharacterBody2D
const TILE_SIZE := 16.0
@export var WALK_SPEED := 5.0
@export var TURN_DURATION := 0.1
enum State {IDLE, TURNING, WALKING, JUMPING}
var current_state = State.IDLE
var facing_direction = Vector2.ZERO
var tile_start_pos: Vector2 = Vector2.ZERO
var tile_target_pos: Vector2 = Vector2.ZERO
var move_progress: float = 0.0
var held_keys: Array = []
var key_hold_times: Dictionary = {}
var turn_timer: float = 0.0
var processing: bool = true

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var anim_state = animation_tree.get("parameters/playback")

func _ready() -> void:
	add_to_group("player")
	tile_start_pos = position; tile_target_pos = position
	
	
func _process(delta: float) -> void:
	update_held_keys(delta)
		
		
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
		var new_facing_direction = input_dir
		
		if new_facing_direction != facing_direction:
			start_turning(new_facing_direction)
		else:
			attempt_movement(input_dir)


func process_turning_state(delta: float) -> void:
	turn_timer += delta
	
	var input_dir = get_input_direction()
	if input_dir != Vector2.ZERO:
		if input_dir == facing_direction:
			var last_key = held_keys.back() if not held_keys.is_empty() else ""
			if last_key in key_hold_times and key_hold_times[last_key] >= TURN_DURATION:
				if attempt_movement(input_dir):
					return
	
	if turn_timer >= TURN_DURATION:
		var blend_dir = facing_direction
		animation_tree.set("parameters/Idle/blend_position", blend_dir)
		
		current_state = State.IDLE
		anim_state.travel("Idle")


func process_walking_state(delta: float) -> void:
	move_progress += WALK_SPEED * delta
	
	if move_progress >= 1.0:
		position = tile_target_pos
		move_progress = 0.0
		Global.step_completed.emit(global_position)
		
		var input_dir = get_input_direction()
		if input_dir != Vector2.ZERO:
			var new_facing_direction = input_dir
			
			if new_facing_direction != facing_direction:
				current_state = State.IDLE
				anim_state.travel("Idle")
				start_turning(new_facing_direction)
			else:
				if not attempt_movement(input_dir):
					current_state = State.IDLE
					anim_state.travel("Idle")
		else:
			current_state = State.IDLE
			anim_state.travel("Idle")
	else:
		position = tile_start_pos.lerp(tile_target_pos, move_progress)


func start_turning(new_facing_direction: Vector2) -> void:
	animation_tree.set("parameters/Turn/blend_position", new_facing_direction)
	animation_tree.set("parameters/Idle/blend_position", new_facing_direction)
	animation_tree.set("parameters/Walk/blend_position", new_facing_direction)
	
	facing_direction = new_facing_direction
	var ray_dir = new_facing_direction
	ray_cast_2d.target_position = ray_dir * TILE_SIZE
	current_state = State.TURNING
	turn_timer = 0.0
	Global.step_completed.emit(global_position)
	anim_state.travel("Turn")


func attempt_movement(input_dir: Vector2) -> bool:
	ray_cast_2d.target_position = input_dir * TILE_SIZE
	ray_cast_2d.force_raycast_update()

	if ray_cast_2d.is_colliding():
		return false
	tile_start_pos = position
	tile_target_pos = position + (input_dir * TILE_SIZE)
	move_progress = 0.0
	current_state = State.WALKING
	
	var blend_dir = input_dir
	animation_tree.set("parameters/Walk/blend_position", blend_dir)
	anim_state.travel("Walk")
	return true


func get_input_direction() -> Vector2:
	if held_keys.is_empty():
		return Vector2.ZERO
	
	var direction_map = {
		"up": Vector2.UP,
		"down": Vector2.DOWN,
		"left": Vector2.LEFT,
		"right": Vector2.RIGHT
	}
	
	var key = held_keys.back()
	return direction_map.get(key, Vector2.ZERO)
	
	
func clear_inputs() -> void:
	held_keys.clear()
	key_hold_times.clear()
	current_state = State.IDLE
	move_progress = 0.0
	anim_state.travel("Idle")


func attempt_interaction() -> void:
	if ray_cast_2d.is_colliding():
		var collider = ray_cast_2d.get_collider()
		if collider.is_in_group("interactable"):
			collider.interact(self)
