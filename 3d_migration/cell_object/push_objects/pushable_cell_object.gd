class_name PushableCellObject
extends CellObject

@export var is_pushable: bool = true

@onready var pivot: Node3D = $Pivot
@onready var gpu_particles_3d: GPUParticles3D = $Pivot/GPUParticles3D


func can_push(direction: Vector3i) -> bool:
	if not is_pushable or direction == Vector3i.ZERO:
		return false
	var player := PlayerContext3D.player
	if player == null or player.grid_map == null:
		return false
	var from_cell: Vector3i = player.get_ground_cell_at(global_position)
	var to_cell := from_cell + direction
	if not player.grid_map.is_nav_walkable_cell(to_cell):
		return false
	return not _has_blocking_collider_at(player.cell_to_world(to_cell))


func push(direction: Vector3i) -> bool:
	if not can_push(direction):
		return false
	var player := PlayerContext3D.player
	var from_cell: Vector3i = player.get_ground_cell_at(global_position)
	var to_cell := from_cell + direction

	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", player.cell_to_world(to_cell), 0.5)

	_angle_pivot_from_dir(direction)
	_play_vfx()

	await tween.finished

	return true


func _has_blocking_collider_at(world_pos: Vector3) -> bool:
	var params := PhysicsPointQueryParameters3D.new()
	params.position = world_pos
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.exclude = [self.get_rid()]
	var hits := get_world_3d().direct_space_state.intersect_point(params, 8)
	for hit in hits:
		var collider: Object = hit.get("collider", null)
		if collider == null or collider == self:
			continue
		if collider is Player3D or collider is Character3D or collider is CellObject:
			return true
	return false


func _play_vfx() -> void:
	if gpu_particles_3d.emitting == true:
		gpu_particles_3d.emitting = false
	gpu_particles_3d.emitting = true


func _angle_pivot_from_dir(dir: Vector3i) -> void:
	match dir:
		Vector3i.FORWARD:
			pivot.rotation_degrees.y = 180.0
		Vector3i.BACK:
			pivot.rotation_degrees.y = 0.0
		Vector3i.LEFT:
			pivot.rotation_degrees.y = 90.0
		Vector3i.RIGHT:
			pivot.rotation_degrees.y = -90.0
