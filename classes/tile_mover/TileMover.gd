class_name TileMover
extends CharacterBody2D

signal finished_turn
signal finished_walk_segment

enum MoveState { IDLE, TURNING, MOVING, JUMPING }
enum Direction { NONE, UP, DOWN, LEFT, RIGHT }

const TILE_SIZE: float = 16.0
const LEDGE_JUMP_DURATION := 0.3
const LEDGE_SPRITE_ARC_PX := 8.0
const _PHYSICS_MASKS := preload("res://classes/physics_layer_masks.gd")

var current_state: MoveState = MoveState.IDLE
var facing_direction: Vector2 = Vector2.ZERO
var tile_start_pos: Vector2 = Vector2.ZERO
var tile_target_pos: Vector2 = Vector2.ZERO
var move_progress: float = 0.0
var eventual_target_pos: Vector2 = Vector2.ZERO
var height_level: int = 0:
	set(value):
		height_level = value
		manage_height()

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var anim_state: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var top_sprite_2d: Sprite2D = $TopSprite2D
@onready var bottom_sprite_2d: Sprite2D = $BottomSprite2D
@onready var shadow_sprite: AnimatedSprite2D = $Shadow


func _ready() -> void:
	sync_tile_positions()
	eventual_target_pos = global_position
	manage_height()


func sync_tile_positions() -> void:
	tile_start_pos = position
	tile_target_pos = position
	eventual_target_pos = global_position
	move_progress = 0.0


func sync_grid_after_external_move() -> void:
	move_progress = 0.0
	tile_start_pos = position
	tile_target_pos = position
	eventual_target_pos = global_position
	if current_state != MoveState.IDLE:
		finish_move_to_idle()


func start_turning(new_facing_direction: Vector2) -> void:
	if new_facing_direction == facing_direction:
		return

	_begin_turn(new_facing_direction)
	await animation_tree.animation_finished
	_finish_turn()


func set_ray_target_facing_tile() -> void:
	if facing_direction != Vector2.ZERO:
		ray_cast_2d.target_position = facing_direction * TILE_SIZE


func get_interaction_ray_collider() -> Object:
	if ray_cast_2d == null:
		return null
	set_ray_target_facing_tile()
	ray_cast_2d.collision_mask = _PHYSICS_MASKS.CHARACTER_INTERACTABLE
	ray_cast_2d.force_raycast_update()
	var collider: Object = ray_cast_2d.get_collider() if ray_cast_2d.is_colliding() else null
	manage_height()
	return collider


func is_direction_blocked(dir: Vector2) -> bool:
	ray_cast_2d.target_position = dir * TILE_SIZE
	ray_cast_2d.force_raycast_update()
	if not ray_cast_2d.is_colliding():
		return false
	return not _ignore_elevated_tilemap_hit_while_on_ground(ray_cast_2d.get_collider())


func try_start_move(dir: Vector2) -> bool:
	if not is_direction_blocked(dir):
		tile_start_pos = position
		tile_target_pos = position + (dir * TILE_SIZE)
		move_progress = 0.0
		current_state = MoveState.MOVING
		animation_tree.set("parameters/Walk/blend_position", _blend_for_cardinal_direction(dir))
		anim_state.travel("Walk")
		return true
	if _should_ledge_jump(dir):
		_run_ledge_jump_async()
		return true
	return false


func check_able_to_move(dir: Vector2) -> bool:
	return try_start_move(dir)


func advance_move(delta: float) -> bool:
	move_progress += _get_walk_speed() * delta

	if move_progress < 1.0:
		position = tile_start_pos.lerp(tile_target_pos, move_progress)
		return false

	position = tile_target_pos
	move_progress = 0.0
	return true


func finish_move_to_idle(last_move_dir: Vector2 = Vector2.ZERO) -> void:
	if last_move_dir != Vector2.ZERO:
		facing_direction = last_move_dir
	animation_tree.set("parameters/Idle/blend_position", _get_idle_blend_position())
	current_state = MoveState.IDLE
	anim_state.travel("Idle")


func walk_list_tiles(tiles: Array[Vector2]) -> void:
	for tile in tiles:
		await walk_to_tile(tile)
		if current_state == MoveState.MOVING or current_state == MoveState.JUMPING:
			await finished_walk_segment


func walk_list_dirs(dirs: Array[Vector2]) -> void:
	var cursor := global_position
	var tiles: Array[Vector2] = []
	for dir in dirs:
		cursor += dir * TILE_SIZE
		tiles.append(cursor)
	await walk_list_tiles(tiles)


func walk_to_tile(pos: Vector2) -> void:
	var dir_vec = _get_step_direction_to(pos)
	eventual_target_pos = pos

	if global_position.is_equal_approx(eventual_target_pos):
		finished_walk_segment.emit()
		return

	if not _is_facing(dir_vec):
		await start_turning(dir_vec)

	if not check_able_to_move(dir_vec):
		finished_walk_segment.emit()


func walk_one_tile(dir: Vector2) -> void:
	var cardinal_dir = Vector2(sign(dir.x), sign(dir.y))
	if abs(cardinal_dir.x) > abs(cardinal_dir.y):
		cardinal_dir = Vector2(cardinal_dir.x, 0)
	elif abs(cardinal_dir.y) > 0.0:
		cardinal_dir = Vector2(0, cardinal_dir.y)
	else:
		cardinal_dir = Vector2.ZERO

	if cardinal_dir == Vector2.ZERO:
		finished_walk_segment.emit()
		return

	await walk_to_tile(global_position + (cardinal_dir * TILE_SIZE))


func animate_move(delta: float) -> void:
	if not advance_move(delta):
		return

	_on_walk_step_completed()

	if global_position.is_equal_approx(eventual_target_pos):
		finish_move_to_idle((tile_target_pos - tile_start_pos).normalized())
		finished_walk_segment.emit()
		return

	var dir_vec = _get_step_direction_to(eventual_target_pos)
	if not check_able_to_move(dir_vec):
		finish_move_to_idle((tile_target_pos - tile_start_pos).normalized())
		finished_walk_segment.emit()


func get_current_map() -> TileMapLayer:
	var current_map = Global.base_map if height_level == 0 else Global.elevated_map
	return current_map


func get_tile_coords() -> Vector2i:
	var current_map = get_current_map()
	var cell = current_map.local_to_map(global_position)
	return cell


func get_next_tile_coords(dir: Vector2) -> Vector2i:
	var result: Vector2i = global_position + dir * Vector2(TILE_SIZE, TILE_SIZE)
	var current_map = get_current_map()
	var cell = current_map.local_to_map(result)
	return cell


func manage_height() -> void:
	if ray_cast_2d == null:
		return
	if height_level == 0:
		z_index = 0
		ray_cast_2d.collision_mask = _PHYSICS_MASKS.RAY_MOVEMENT_GROUND
	else:
		z_index = 2
		ray_cast_2d.collision_mask = _PHYSICS_MASKS.RAY_MOVEMENT_ELEVATED


func _ignore_elevated_tilemap_hit_while_on_ground(collider: Object) -> bool:
	return height_level == 0 \
	and Global.elevated_map != null \
	and collider == Global.elevated_map


func _ray_hits_solid_for_movement(dir: Vector2, length_scale: float) -> bool:
	ray_cast_2d.target_position = dir * TILE_SIZE * length_scale
	ray_cast_2d.force_raycast_update()
	if not ray_cast_2d.is_colliding():
		return false
	return not _ignore_elevated_tilemap_hit_while_on_ground(ray_cast_2d.get_collider())


func _should_ledge_jump(dir: Vector2) -> bool:
	if not _ray_hits_solid_for_movement(dir, 0.5):
		set_ray_target_facing_tile()
		return false
	var collider := ray_cast_2d.get_collider()
	if collider == null or not collider.is_in_group("ledge"):
		set_ray_target_facing_tile()
		return false
	var allowed_raw = collider.get("allowed_direction")
	var allowed_dir: Direction
	if allowed_raw is Direction:
		allowed_dir = allowed_raw
	elif typeof(allowed_raw) == TYPE_INT:
		allowed_dir = allowed_raw as Direction
	else:
		set_ray_target_facing_tile()
		return false
	if allowed_dir == Direction.NONE:
		set_ray_target_facing_tile()
		return false
	var allowed_vec := _vector_from_dir(allowed_dir)
	if allowed_vec == Vector2.ZERO:
		set_ray_target_facing_tile()
		return false
	var should_jump := facing_direction.dot(allowed_vec) < 0.0
	set_ray_target_facing_tile()
	return should_jump


func _run_ledge_jump_async() -> void:
	_set_movement_locked(true)
	current_state = MoveState.JUMPING
	var hop := facing_direction * TILE_SIZE * 2.0
	var blend := _blend_for_cardinal_direction(facing_direction)
	animation_tree.set("parameters/Jump/blend_position", blend)
	anim_state.travel("Jump")
	shadow_sprite.visible = true
	shadow_sprite.play()

	var tree := get_tree()
	if tree == null:
		push_warning("ledge jump: get_tree() null, aborting")
		current_state = MoveState.IDLE
		_set_movement_locked(false)
		return

	var top_base := top_sprite_2d.position
	var bot_base := bottom_sprite_2d.position
	var arc := Vector2(0, -LEDGE_SPRITE_ARC_PX)
	var half_dur := LEDGE_JUMP_DURATION * 0.5
	var land_pos := position + hop

	var pos_tween := create_tween()
	pos_tween.tween_property(self, "position", land_pos, LEDGE_JUMP_DURATION)

	var up_tween := create_tween()
	up_tween.set_parallel(true)
	up_tween.tween_property(top_sprite_2d, "position", top_base + arc, half_dur)
	up_tween.tween_property(bottom_sprite_2d, "position", bot_base + arc, half_dur)

	await tree.create_timer(half_dur, true).timeout

	var down_tween := create_tween()
	down_tween.set_parallel(true)
	down_tween.tween_property(top_sprite_2d, "position", top_base, half_dur)
	down_tween.tween_property(bottom_sprite_2d, "position", bot_base, half_dur)

	await tree.create_timer(half_dur, true).timeout

	position = land_pos
	top_sprite_2d.position = top_base
	bottom_sprite_2d.position = bot_base

	shadow_sprite.stop()
	shadow_sprite.visible = false
	tile_start_pos = position
	tile_target_pos = position
	_on_walk_step_completed()
	_ledge_jump_finalize()
	_set_movement_locked(false)


func _ledge_jump_finalize() -> void:
	if _should_continue_path_after_lock():
		var dir_vec = _get_step_direction_to(eventual_target_pos)
		if try_start_move(dir_vec):
			return
	finish_move_to_idle()
	finished_walk_segment.emit()


func _should_continue_path_after_lock() -> bool:
	return not global_position.is_equal_approx(eventual_target_pos)


func _set_movement_locked(_locked: bool) -> void:
	pass


func _get_walk_speed() -> float:
	return 4.0


func _blend_for_cardinal_direction(dir: Vector2) -> Vector2:
	return dir


func _get_idle_blend_position() -> Vector2:
	return facing_direction


func _set_blend_positions(dir: Vector2) -> void:
	var blend := _blend_for_cardinal_direction(dir)
	animation_tree.set("parameters/Turn/blend_position", blend)
	animation_tree.set("parameters/Idle/blend_position", blend)
	animation_tree.set("parameters/Walk/blend_position", blend)


func _begin_turn(new_facing_direction: Vector2) -> void:
	_set_blend_positions(new_facing_direction)
	facing_direction = new_facing_direction
	ray_cast_2d.target_position = new_facing_direction * TILE_SIZE
	current_state = MoveState.TURNING
	anim_state.travel("Turn")


func _finish_turn() -> void:
	animation_tree.set("parameters/Idle/blend_position", _get_idle_blend_position())
	current_state = MoveState.IDLE
	anim_state.travel("Idle")
	finished_turn.emit()


func _on_walk_step_completed() -> void:
	pass


func _is_facing(dir: Vector2) -> bool:
	return facing_direction == dir


func _get_step_direction_to(target_pos: Vector2) -> Vector2:
	var dir_vec = (target_pos - global_position).normalized()
	if abs(dir_vec.x) > abs(dir_vec.y):
		return Vector2(sign(dir_vec.x), 0)
	if abs(dir_vec.y) > 0.0:
		return Vector2(0, sign(dir_vec.y))
	return Vector2.ZERO


func _vector_from_dir(dir: Direction) -> Vector2:
	match dir:
		Direction.UP:
			return Vector2.UP
		Direction.DOWN:
			return Vector2.DOWN
		Direction.LEFT:
			return Vector2.LEFT
		Direction.RIGHT:
			return Vector2.RIGHT
		_:
			return Vector2.ZERO


func _direction_from_vector(vector: Vector2) -> Direction:
	match vector:
		Vector2.UP:
			return Direction.UP
		Vector2.DOWN:
			return Direction.DOWN
		Vector2.LEFT:
			return Direction.LEFT
		Vector2.RIGHT:
			return Direction.RIGHT
		_:
			return Direction.NONE
