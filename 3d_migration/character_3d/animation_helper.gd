class_name AnimationHelper
extends Resource

const TURN_WAIT_MAX_FRAMES := 180

var animation_tree: AnimationTree
var camera_3d: Camera3D


func state_machine_playback() -> AnimationNodeStateMachinePlayback:
	if animation_tree == null:
		return null
	return animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback


func world_dir_from_grid(dir: Vector3i) -> Vector3:
	return Vector3(float(dir.x), 0.0, float(dir.z)).normalized()


func camera_relative_blend(world_dir: Vector3) -> Vector2:
	var wd := world_dir
	wd.y = 0.0
	if wd.length_squared() < 0.0001:
		return Vector2(0.0, 1.0)
	wd = wd.normalized()

	var yaw_src: Node3D = camera_3d
	var pivot_node: Variant = camera_3d.get("pivot") if camera_3d else null
	if pivot_node is Node3D:
		yaw_src = pivot_node

	var right := yaw_src.global_transform.basis.x
	right.y = 0.0
	if right.length_squared() < 0.0001:
		right = Vector3.RIGHT
	else:
		right = right.normalized()

	var forward := -yaw_src.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3(0.0, 0.0, 1.0)
	else:
		forward = forward.normalized()

	var blend := Vector2(wd.dot(right), -wd.dot(forward))
	if blend.length_squared() < 0.0001:
		return Vector2(0.0, 1.0)
	return blend.normalized()


func blend_for_facing(facing_grid: Vector3i) -> Vector2:
	return camera_relative_blend(world_dir_from_grid(facing_grid))


func apply_direction_blends(blend: Vector2) -> void:
	if animation_tree == null:
		return
	animation_tree.set("parameters/Idle/blend_position", blend)
	animation_tree.set("parameters/Surf/blend_position", blend)
	animation_tree.set("parameters/Walk/blend_position", blend)
	animation_tree.set("parameters/Slide/blend_position", blend)
	animation_tree.set("parameters/Turn/blend_position", blend)
	animation_tree.set("parameters/Jump/blend_position", blend)


func refresh_facing_blends(facing_grid: Vector3i, tree_owner: Node) -> void:
	if not tree_owner.is_inside_tree() or camera_3d == null or animation_tree == null:
		return
	var sm := state_machine_playback()
	if sm and sm.get_current_node() == &"Turn":
		return
	apply_direction_blends(blend_for_facing(facing_grid))


func await_turn_finished(tree_owner: Node) -> void:
	var sm := state_machine_playback()
	if sm == null:
		return
	var frames := 0
	while sm.get_current_node() == &"Turn":
		frames += 1
		if frames > TURN_WAIT_MAX_FRAMES:
			break
		await tree_owner.get_tree().process_frame


func apply_blends_for_grid_direction(direction: Vector3i) -> void:
	apply_direction_blends(camera_relative_blend(world_dir_from_grid(direction)))


func play_turn_toward(direction: Vector3i, current_facing: Vector3i, tree_owner: Node) -> void:
	if direction == current_facing:
		return
	if animation_tree == null or camera_3d == null:
		return
	apply_blends_for_grid_direction(direction)
	var sm_turn := state_machine_playback()
	if sm_turn:
		sm_turn.start(&"Turn")
	await await_turn_finished(tree_owner)
	apply_direction_blends(blend_for_facing(direction))
	var sm_idle := state_machine_playback()
	if sm_idle:
		sm_idle.start(&"Idle")
