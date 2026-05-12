class_name PivotCamera3D
extends Camera3D

signal rotation_finished
signal rotation_midpoint_reached

@export var step_degrees := 90.0
@export var tween_duration := 0.5
@export var los_sample_step_fraction := 0.25
@export var los_ray_end_inset: float = 0.08

var pivot: Node3D
var _rotating := false


func is_player_occluded() -> bool:
	return _player_is_occluded()


func is_pivot_orbiting() -> bool:
	return _rotating


func _rotate_camera(direction_sign: int) -> void:
	if _rotating or pivot == null:
		return
	_rotating = true
	var target := pivot.rotation_degrees + Vector3(0, float(direction_sign) * step_degrees, 0)
	var tween := get_tree().create_tween()

	tween.tween_property(pivot, "rotation_degrees", target, tween_duration).set_trans(Tween.TRANS_LINEAR) # gdlint-ignore
	tween.parallel().tween_callback(func(): rotation_midpoint_reached.emit()).set_delay(tween_duration * 0.5) # gdlint-ignore
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


func _player_is_occluded() -> bool:
	var player = PlayerContext3D.player
	if player == null:
		return false
	var grid_map: CombinedGridMap = player.grid_map
	if grid_map == null:
		return false
	var movement_helper = player.movement_helper
	var camera_global_position: Vector3 = global_position
	var player_sample_global_position: Vector3 = player.global_position
	var to_player: Vector3 = player_sample_global_position - camera_global_position
	var dist: float = to_player.length()
	if dist <= los_ray_end_inset:
		return false
	var dir: Vector3 = to_player / dist
	var cs: Vector3 = grid_map.cell_size
	var cell_ext: float = minf(minf(cs.x, cs.y), cs.z)
	var step_len: float = maxf(cell_ext * los_sample_step_fraction, 0.04)
	var cam_cell: Vector3i = movement_helper.get_cell_at_world(camera_global_position, grid_map)
	var target_cell: Vector3i = movement_helper.get_cell_at_world(player_sample_global_position, grid_map)
	var last_cell := Vector3i(2147483647, 2147483647, 2147483647)
	var traveled: float = step_len * 0.5
	var grid_blocked := false
	while traveled < dist - los_ray_end_inset:
		var sample: Vector3 = camera_global_position + dir * traveled
		var cell: Vector3i = movement_helper.get_cell_at_world(sample, grid_map)
		if cell != cam_cell and cell != target_cell and cell != last_cell:
			last_cell = cell
			if grid_map.cell_blocks_los(cell):
				grid_blocked = true
				break
		traveled += step_len
	return grid_blocked
