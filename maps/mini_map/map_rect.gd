class_name MapRect
extends NinePatchRect

signal cursor_entered(cursor_location: Map.Location)
signal cursor_exited(cursor_location: Map.Location)

const MINIMAP_CURSOR_PHYSICS_LAYER: int = 1 << 19

const BRIGHTEST: float = 0.7
const FLASH_DURATION: float = 0.5
const BOBBLE_DURATION: float = 0.15

@export var location: Map.Location = Map.Location.NONE

var cursor: CharacterBody2D = null
var flash_tween: Tween = null
var bobble_tween: Tween = null

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var sprite_start: Vector2 = Vector2.ZERO
@onready var sprite_end: Vector2 = Vector2.ZERO
@onready var area_2d: Area2D = $Area2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D


func _ready() -> void:
	if not is_node_ready():
		return
	if collision_shape_2d and collision_shape_2d.shape:
		collision_shape_2d.shape = collision_shape_2d.shape.duplicate()
	area_2d.collision_mask = MINIMAP_CURSOR_PHYSICS_LAYER
	_connect_signals()
	_position_head()


func start_flashing() -> void:
	material = material as ShaderMaterial
	flash_tween = create_tween().set_loops()
	flash_tween.tween_method(
		func(v: float) -> void: material.set_shader_parameter("flash_amount", v),
		0.0,
		BRIGHTEST,
		FLASH_DURATION,
	)
	flash_tween.tween_method(
		func(v: float) -> void: material.set_shader_parameter("flash_amount", v),
		BRIGHTEST,
		0.0,
		FLASH_DURATION,
	)


func stop_flashing() -> void:
	if flash_tween:
		flash_tween.kill()
	material.set_shader_parameter("flash_amount", 0.0)


func _connect_signals() -> void:
	Global.location_changed.connect(_on_location_changed)
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)


func _on_location_changed(player_location: Map.Location) -> void:
	if location == player_location:
		_toggle_head_visible(true)
		_position_head()
		_animate_head_bobble()
		if cursor:
			_position_cursor()
	else:
		_toggle_head_visible(false)


func _calculate_center_position() -> Vector2:
	return size / 2


func _position_cursor() -> void:
	if cursor == null:
		return
	cursor.global_position = get_global_transform_with_canvas() * _calculate_center_position()


func _position_head() -> void:
	sprite_2d.position = _calculate_center_position()
	sprite_start = sprite_2d.position
	sprite_end = Vector2(sprite_start.x, sprite_start.y - scale.y)
	_sync_collision_rect()


func _sync_collision_rect() -> void:
	if collision_shape_2d == null:
		return
	var rect_shape := collision_shape_2d.shape as RectangleShape2D
	if rect_shape == null:
		return
	rect_shape.size = size
	collision_shape_2d.position = size / 2.0


func _toggle_head_visible(val: bool) -> void:
	if not val:
		if bobble_tween:
			bobble_tween.kill()
			bobble_tween = null
		_position_head()
	sprite_2d.visible = val


func _animate_head_bobble() -> void:
	if bobble_tween:
		bobble_tween.kill()
	bobble_tween = create_tween().set_loops()
	var tween = bobble_tween
	tween.tween_interval(BOBBLE_DURATION * 4)
	tween.tween_method(
		func(v: Vector2) -> void: sprite_2d.position = v,
		sprite_start,
		sprite_end,
		BOBBLE_DURATION,
	)
	tween.tween_method(
		func(v: Vector2) -> void: sprite_2d.position = v,
		sprite_end,
		sprite_start,
		BOBBLE_DURATION,
	)


func _on_body_entered(_body: Object) -> void:
	cursor_entered.emit(location)


func _on_body_exited(_body: Object) -> void:
	cursor_exited.emit(location)
