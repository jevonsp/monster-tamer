class_name TileMover
extends CharacterBody2D

signal finished_turn
signal finished_walk_segment

enum MoveState { IDLE, TURNING, MOVING, JUMPING }
enum Direction { NONE, UP, DOWN, LEFT, RIGHT }

const TILE_SIZE: float = 16.0
## 1-based indices from Project Settings → Layer Names → 2D Physics.
const _PHYS_LAYER_WORLD: int = 1
const _PHYS_LAYER_INTERACTABLES: int = 4
const _PHYS_LAYER_ELEVATED: int = 8
const _PHYS_LAYER_ELEVATED_INTERACTABLES: int = 9
const _DEBUG_LAYER_BY_BIT: Dictionary = {
	0: "1:World",
	1: "2:Player",
	2: "3:Zones",
	3: "4:Interactables",
	7: "8:Bridge",
}

@export var height_level: int = 0:
	set(value):
		height_level = value
		z_index = render_z_elevated if height_level == 1 else render_z_ground
		_apply_height_physics_masks()
## Draw order only; must stay independent of Global.world_map lookup.
## Elevated default above TileMapLayer so y_sort does not bury the sprite under deck tiles.
@export var render_z_ground: int = 0
@export var render_z_elevated: int = 12
## Log RayCast2D.collision_mask + z_index whenever height/mask is applied.
@export var debug_height_ray_z: bool = false
## Log cell / feet / from_tile every step (spammy). If false, only logs when tile height disagrees with height_level.
@export var debug_height_sync_each_step: bool = false

var current_state: MoveState = MoveState.IDLE
var facing_direction: Vector2 = Vector2.ZERO
var tile_start_pos: Vector2 = Vector2.ZERO
var tile_target_pos: Vector2 = Vector2.ZERO
var move_progress: float = 0.0
var eventual_target_pos: Vector2 = Vector2.ZERO

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var anim_state: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var ray_cast_2d: RayCast2D = $RayCast2D


func _ready() -> void:
	sync_tile_positions()
	eventual_target_pos = global_position
	_apply_height_physics_masks()
	sync_height_from_stand_tile()


func sync_tile_positions() -> void:
	tile_start_pos = position
	tile_target_pos = position
	eventual_target_pos = global_position


func start_turning(new_facing_direction: Vector2) -> void:
	if new_facing_direction == facing_direction:
		return

	_begin_turn(new_facing_direction)
	await animation_tree.animation_finished
	_finish_turn()


func is_direction_blocked(dir: Vector2) -> bool:
	ray_cast_2d.target_position = dir * TILE_SIZE
	ray_cast_2d.force_raycast_update()
	return ray_cast_2d.is_colliding()


func try_start_move(dir: Vector2) -> bool:
	if is_direction_blocked(dir):
		return false

	tile_start_pos = position
	tile_target_pos = position + (dir * TILE_SIZE)
	move_progress = 0.0
	current_state = MoveState.MOVING
	animation_tree.set("parameters/Walk/blend_position", _blend_for_cardinal_direction(dir))
	anim_state.travel("Walk")
	return true


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
		# walk_to_tile emits finished_walk_segment immediately when already at the tile or
		# when the raycast says blocked; only await when a real walk step was started.
		if current_state == MoveState.MOVING:
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

	if check_able_to_move(dir_vec):
		current_state = MoveState.MOVING
	else:
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
	if FieldMaps.ground != null:
		return FieldMaps.ground
	if Global.ground_map != null:
		return Global.ground_map
	return Global.world_map


func sync_height_from_stand_tile() -> void:
	var feet: Vector2 = _feet_global()
	var cells: Dictionary = TerrainHeight.cells_under_feet(feet)
	var ground_cell: Vector2i = cells["ground_cell"]
	var bridge_cell: Vector2i = cells["bridge_cell"]
	var want_height: int = TerrainHeight.resolve(feet)
	var ground: TileMapLayer = get_current_map()
	var mismatch: bool = want_height != height_level
	if debug_height_ray_z and (debug_height_sync_each_step or mismatch):
		var gtxt: String = _debug_standing_tile_line(ground, ground_cell) if ground else "no ground_map"
		var bridge: TileMapLayer = FieldMaps.bridge if FieldMaps.bridge != null else Global.bridge_map
		var btxt: String
		if bridge != null:
			btxt = " | bridge_cell=%s %s" % [bridge_cell, _debug_standing_tile_line(bridge, bridge_cell)]
		else:
			btxt = " | bridge_map=null bridge_cell=%s (n/a)" % bridge_cell
		print(
			"[%s] sync_tile | feet_global=%s want_height=%d height_level=%d%s | ground_cell=%s | %s%s" % [
				name,
				feet,
				want_height,
				height_level,
				" *** MISMATCH ***" if mismatch else "",
				ground_cell,
				gtxt,
				btxt,
			],
		)
	if mismatch:
		height_level = want_height


func _debug_mask_layer_str(mask: int) -> String:
	if mask < 0:
		return "n/a"
	var parts: PackedStringArray = PackedStringArray()
	for bit in 32:
		if mask & (1 << bit):
			parts.append(str(_DEBUG_LAYER_BY_BIT.get(bit, "L%d" % (bit + 1))))
	return ", ".join(parts)


func _print_height_ray_z(context: String) -> void:
	if not debug_height_ray_z:
		return
	var ray_m: int = ray_cast_2d.collision_mask if ray_cast_2d else -1
	var body_m: int = collision_mask
	print(
		"[%s] %s | height_level=%d z_index=%d ray_mask=%d [%s] body_mask=%d [%s]" % [
			name,
			context,
			height_level,
			z_index,
			ray_m,
			_debug_mask_layer_str(ray_m),
			body_m,
			_debug_mask_layer_str(body_m),
		],
	)


func _debug_standing_tile_line(map: TileMapLayer, cell: Vector2i) -> String:
	var src_id: int = map.get_cell_source_id(cell)
	if src_id == -1:
		return "standing_tile: EMPTY (no tile at cell) is_elevated=n/a"
	var atlas: Vector2i = map.get_cell_atlas_coords(cell)
	var elevated: bool = TileChecker.is_tile_elevated(cell, map)
	return "standing_tile: source_id=%d atlas_coords=%s is_elevated=%s" % [src_id, atlas, elevated]


func _apply_height_physics_masks() -> void:
	# Clear all bits first so scene defaults / stale bits never leave Bridge (8) on when grounded.
	for layer_i in range(1, 33):
		set_collision_mask_value(layer_i, false)
		if ray_cast_2d:
			ray_cast_2d.set_collision_mask_value(layer_i, false)
	if height_level == 1:
		if ray_cast_2d:
			ray_cast_2d.set_collision_mask_value(_PHYS_LAYER_ELEVATED, true)
			ray_cast_2d.set_collision_mask_value(_PHYS_LAYER_INTERACTABLES, false)
			ray_cast_2d.set_collision_mask_value(_PHYS_LAYER_ELEVATED_INTERACTABLES, true)
		set_collision_mask_value(_PHYS_LAYER_ELEVATED, true)
		set_collision_mask_value(_PHYS_LAYER_INTERACTABLES, false)
		set_collision_mask_value(_PHYS_LAYER_ELEVATED_INTERACTABLES, true)
	else:
		if ray_cast_2d:
			ray_cast_2d.set_collision_mask_value(_PHYS_LAYER_ELEVATED, false)
			ray_cast_2d.set_collision_mask_value(_PHYS_LAYER_INTERACTABLES, true)
			ray_cast_2d.set_collision_mask_value(_PHYS_LAYER_ELEVATED_INTERACTABLES, false)
		set_collision_mask_value(_PHYS_LAYER_ELEVATED, false)
		set_collision_mask_value(_PHYS_LAYER_INTERACTABLES, true)
		set_collision_mask_value(_PHYS_LAYER_ELEVATED_INTERACTABLES, false)

	_print_height_ray_z("apply_height_masks")


func _feet_global() -> Vector2:
	return global_position + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)


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
	sync_height_from_stand_tile()


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


func _get_next_tile_coords(dir: Vector2) -> Vector2i:
	var map := get_current_map()
	if map == null:
		return Vector2i.ZERO
	var next_feet: Vector2 = _feet_global() + dir * Vector2(TILE_SIZE, TILE_SIZE)
	return map.local_to_map(map.to_local(next_feet))
