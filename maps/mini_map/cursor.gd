extends CharacterBody2D

@export var max_speed: float = 130.0
@export var acceleration: float = 520.0
@export var friction: float = 980.0

var processing: bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	if not processing:
		return
	_process_movement_keys(delta)


func get_input_direction() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("right"):
		dir.x += 1.0
	if Input.is_action_pressed("left"):
		dir.x -= 1.0
	if Input.is_action_pressed("down"):
		dir.y += 1.0
	if Input.is_action_pressed("up"):
		dir.y -= 1.0
	return dir


func start_animation() -> void:
	animated_sprite_2d.frame = 0
	animated_sprite_2d.play()


func stop_animation() -> void:
	animated_sprite_2d.stop()


func _process_movement_keys(delta: float) -> void:
	var input_dir = get_input_direction()
	_move(input_dir, delta)


func _move(input_dir: Vector2, delta: float) -> void:
	var target := Vector2.ZERO
	if input_dir != Vector2.ZERO:
		target = input_dir.normalized() * max_speed
		velocity = velocity.move_toward(target, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()
