class_name NPC3D
extends Character3D

const MAX_CAMERA_BIND_ATTEMPTS := 120

@export var command_lists: Array[CommandList] = []
@export var command_index: int = 0

var _camera_signals_connected := false
var _bind_attempts := 0


func _ready() -> void:
	animation_tree.anim_player = NodePath("../AnimationPlayer")
	animation_tree.active = true
	animation_tree.advance(0.0)
	anim_helper.animation_tree = animation_tree
	_bind_camera_and_connect()


func _process(_delta: float) -> void:
	var cam: Camera3D = PlayerContext3D.camera_3d
	if cam == null:
		return
	if cam.has_method("is_pivot_orbiting") and cam.is_pivot_orbiting():
		anim_helper.refresh_facing_blends(facing_grid, self)


func interact(player: Player3D) -> void:
	if player == null:
		return
	var toward := _grid_direction_toward(player.global_position)
	if toward == Vector3i.ZERO:
		return
	ray_cast_3d.target_position = Vector3(toward)
	ray_cast_3d.force_raycast_update()
	set_facing_grid(toward)
	_on_player_interact()


func set_facing_grid(dir: Vector3i) -> void:
	facing_grid = dir
	if PlayerContext3D.camera_3d:
		anim_helper.camera_3d = PlayerContext3D.camera_3d
	anim_helper.refresh_facing_blends(facing_grid, self)


func change_command_index_to(index: int) -> void:
	if index > command_lists.size():
		return

	command_index = index


func _bind_camera_and_connect() -> void:
	var cam: Camera3D = PlayerContext3D.camera_3d
	if cam == null:
		_bind_attempts += 1
		if _bind_attempts < MAX_CAMERA_BIND_ATTEMPTS:
			call_deferred("_bind_camera_and_connect")
		return
	_bind_attempts = 0
	anim_helper.camera_3d = cam
	if not _camera_signals_connected:
		cam.rotation_midpoint_reached.connect(_on_camera_rotation_finished)
		cam.rotation_finished.connect(_on_camera_rotation_finished)
		_camera_signals_connected = true
	anim_helper.call_deferred("refresh_facing_blends", facing_grid, self)


func _on_camera_rotation_finished() -> void:
	var cam: Camera3D = PlayerContext3D.camera_3d
	if cam:
		anim_helper.camera_3d = cam
	anim_helper.refresh_facing_blends(facing_grid, self)


func _grid_direction_toward(world_point: Vector3) -> Vector3i:
	var flat := world_point - global_position
	flat.y = 0.0
	if flat.length_squared() < 0.0001:
		return Vector3i.ZERO
	flat = flat.normalized()
	if absf(flat.x) >= absf(flat.z):
		return Vector3i(1, 0, 0) if flat.x > 0.0 else Vector3i(-1, 0, 0)
	return Vector3i(0, 0, 1) if flat.z > 0.0 else Vector3i(0, 0, -1)


func _on_player_interact() -> void:
	PlayerContext3D.toggle_player.emit(false)
	PlayerContext3D.player.clear_inputs()

	if command_lists.is_empty():
		return
	if command_index >= command_lists.size():
		return
	await command_lists[command_index].run(self)

	PlayerContext3D.player.clear_inputs()
	PlayerContext3D.toggle_player.emit(true)
