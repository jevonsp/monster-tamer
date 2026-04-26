class_name PivotCamera3D
extends Camera3D

signal rotation_finished
signal rotation_midpoint_reached

@export var step_degrees := 90.0
@export var tween_duration := 0.5

var pivot: Node3D
var _rotating := false


func is_pivot_orbiting() -> bool:
	return _rotating


func _rotate_camera(direction_sign: int) -> void:
	if _rotating or pivot == null:
		return
	_rotating = true
	var target := pivot.rotation_degrees + Vector3(0, float(direction_sign) * step_degrees, 0)
	var tween := get_tree().create_tween()
	tween.tween_property(pivot, "rotation_degrees", target, tween_duration).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_callback(func(): rotation_midpoint_reached.emit()).set_delay(tween_duration * 0.5)
	await tween.finished
	_rotating = false
	rotation_finished.emit()


func _on_side_scrolling_started() -> void:
	if pivot == null:
		return
	if _rotating:
		await rotation_finished
	pivot.rotation.x = -45


func _on_side_scrolling_finished() -> void:
	if pivot == null:
		return
	if _rotating:
		await rotation_finished
	pivot.rotation.x = 0
