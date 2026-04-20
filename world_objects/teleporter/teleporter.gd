@tool
class_name Teleporter
extends Node2D

enum TransitionType { IRIS }

@export var is_door_visible: bool = true:
	set(value):
		is_door_visible = value
		if not is_node_ready():
			return
		if Engine.is_editor_hint():
			_toggle_door_visible(is_door_visible)
@export var transition_type: TransitionType = TransitionType.IRIS
@export var teleporter_point: TeleporterPoint

@onready var iris_color_rect: ColorRect = $CanvasLayer/IrisColorRect
@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:
	assert(teleporter_point != null)


func _teleport_sequence_iris(body: CharacterBody2D) -> void:
	(body as Player)._set_movement_locked(true)
	(body as Player).clear_inputs()
	iris_color_rect.visible = true
	await _iris_close()
	_teleport_player(body)
	await _iris_open()
	iris_color_rect.visible = false
	(body as Player)._set_movement_locked(false)


func _teleport_player(body: CharacterBody2D) -> void:
	body.global_position = teleporter_point.global_position
	if body is TileMover:
		(body as TileMover).sync_grid_after_external_move()


func _iris_open(duration: float = 1.0) -> void:
	await _tween_iris(0.0, 1.0, duration)


func _iris_close(duration: float = 1.0) -> void:
	await _tween_iris(1.0, 0.0, duration)


func _tween_iris(from: float, to: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_method(
		func(v: float) -> void: iris_color_rect.material.set_shader_parameter("iris_size", v),
		from,
		to,
		duration,
	)
	await tween.finished


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is not Player:
		return

	await Global.step_completed

	var interfaces = get_tree().get_first_node_in_group("interfaces")
	if interfaces and interfaces.has_method("begin_field_suppress"):
		interfaces.begin_field_suppress()

	match transition_type:
		TransitionType.IRIS:
			await _teleport_sequence_iris(body)

	if interfaces and interfaces.has_method("end_field_suppress"):
		interfaces.end_field_suppress()


func _toggle_door_visible(value: bool) -> void:
	sprite_2d.visible = value
