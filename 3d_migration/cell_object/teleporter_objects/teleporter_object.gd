@tool
class_name TeleporterObject
extends CellObject

signal transition_animation_complete

enum TransitionType { IRIS }

@export var teleporter_point: TeleporterPoint3D
@export var transition_type: TransitionType = TransitionType.IRIS

@onready var iris_color_rect: ColorRect = $CanvasLayer/IrisColorRect


func _teleport_sequence_iris(player: Player3D) -> void:
	player.set_movement_locked(true)
	player.clear_inputs()
	iris_color_rect.visible = true
	await _iris_close()
	_teleport_player(player)
	await _iris_open()
	iris_color_rect.visible = false
	player.set_movement_locked(false)


func _teleport_player(player: Player3D) -> void:
	if teleporter_point == null or player.grid_map == null:
		return
	var sample: Vector3 = teleporter_point.global_position
	if teleporter_point.marker:
		sample = teleporter_point.marker.global_position
	var cell: Vector3i = player.helper.get_ground_cell(
		sample,
		player.grid_map,
		Character3D.HEIGHT_ADJUSTMENT,
	)
	player.global_position = Vector3(cell) + Character3D.HEIGHT_ADJUSTMENT


func _iris_open(duration: float = 1.0) -> void:
	await _tween_iris(0.0, 1.0, duration)


func _iris_close(duration: float = 1.0) -> void:
	await _tween_iris(1.0, 0.0, duration)
	transition_animation_complete.emit()


func _tween_iris(from: float, to: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_method(
		func(v: float) -> void: iris_color_rect.material.set_shader_parameter("iris_size", v),
		from,
		to,
		duration,
	)
	await tween.finished


func _on_area_entered(area: Area3D) -> void:
	if area is not Player3D:
		return

	_play_animation()

	await PlayerContext3D.walk_segmented_completed

	var interfaces = get_tree().get_first_node_in_group("interfaces")
	if interfaces and interfaces.has_method("begin_field_suppress"):
		interfaces.begin_field_suppress()

	match transition_type:
		TransitionType.IRIS:
			await _teleport_sequence_iris(area)

	if interfaces and interfaces.has_method("end_field_suppress"):
		interfaces.end_field_suppress()


func _play_animation() -> void:
	pass
