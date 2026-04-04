class_name Teleporter
extends Node2D

enum TransitionType { IRIS }

@export var transition_type: TransitionType = TransitionType.IRIS
@export var teleporter_point: TeleporterPoint

@onready var iris_color_rect: ColorRect = $CanvasLayer/IrisColorRect


func _ready() -> void:
	assert(teleporter_point != null)


func _teleport_sequence_iris(body: CharacterBody2D) -> void:
	iris_color_rect.visible = true
	await _iris_close()
	_teleport_player(body)
	await _iris_open()
	iris_color_rect.visible = false


func _teleport_player(body: CharacterBody2D) -> void:
	body.global_position = teleporter_point.global_position


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
