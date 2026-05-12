class_name CombinedGridMap
extends Node3D

const TILE_DICT: Dictionary = {
	STAIRS = 1,
	LEDGE = 15,
	WATER = 16,
	ICE = 33,
}
const WATER_DICT: Dictionary = {
	WATER_0 = 16,
	WATER_1 = 17,
	WATER_2 = 18,
	WATER_3 = 19,
	WATER_4 = 20,
	WATER_5 = 21,
	WATER_6 = 22,
	WATER_7 = 23,
}
const _LEDGE_MAX_HORIZONTAL_SCAN := 4
const _LEDGE_MAX_VERTICAL_SCAN := 4
const INVALID_WORLD_CELL := Vector3i(2147483647, 2147483647, 2147483647)

@export var mesh_flags: Dictionary[int, TileFlags]
@export_subgroup("Animation Values")
@export var water_animation_interval := 0.25

var gm_translator: GridMapTranslator
var cell_flags: Dictionary[Vector3i, TileFlags] = { }
var graph: Dictionary[Vector3i, Array] = { }
var used_cells: Array[Vector3i] = []
var stairs: Array[Vector3i] = []
var water: Array[Vector3i] = []
var water_animation_timer := 0.0
var water_frame := 0
var water_direction := 1
var cell_size: Vector3:
	get:
		if _terrain_chunks.is_empty():
			return Vector3.ONE
		return _terrain_chunks[0].cell_size
var player_3d: Player3D
var _world_owner_gm: Dictionary = { }
var _world_owner_local: Dictionary = { }
var _terrain_chunks: Array[GridMap] = []


func _ready() -> void:
	set_process(false)
	_terrain_chunks.clear()
	for child in get_children():
		if child is GridMap:
			_terrain_chunks.append(child)
	if _terrain_chunks.is_empty():
		push_error("CombinedGridMap: no GridMap children; world queries are invalid.")
	gm_translator = GridMapTranslator.new(_terrain_chunks)
	_rebuild_world_cell_index()
	stairs = get_used_cells_by_item(TILE_DICT.STAIRS)
	_collect_water_cells()
	_build_cell_flags()
	_build_graph_edges()
	if not water.is_empty():
		set_process(true)
	for child in get_children():
		if child is Player3D:
			player_3d = child
	for child in get_parent().get_children():
		if child is Player3D:
			player_3d = child
	if not player_3d:
		return
	if not player_3d.grid_map:
		player_3d.grid_map = self


func _process(delta: float) -> void:
	water_animation_timer += delta
	if water_animation_timer >= water_animation_interval:
		_animate_water_cells()
		water_animation_timer = 0.0


func world_cell_at_global_position(world_position: Vector3) -> Vector3i:
	if _terrain_chunks.is_empty():
		return INVALID_WORLD_CELL
	for gm: GridMap in _terrain_chunks:
		var lc := gm.local_to_map(gm.to_local(world_position))
		if gm.get_cell_item(lc) != GridMap.INVALID_CELL_ITEM:
			return gm_translator.local_to_world(lc, gm)
	var gm0: GridMap = _terrain_chunks[0]
	var lc0 := gm0.local_to_map(gm0.to_local(world_position))
	return gm_translator.local_to_world(lc0, gm0)


func get_used_cells() -> Array[Vector3i]:
	return used_cells


func get_used_cells_by_item(item: int) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for c: Vector3i in used_cells:
		if get_cell_item(c) == item:
			out.append(c)
	return out


func get_cell_item(world_cell: Vector3i) -> int:
	var gm: GridMap = _world_owner_gm.get(world_cell, null)
	if gm == null:
		return GridMap.INVALID_CELL_ITEM
	return gm.get_cell_item(_world_owner_local[world_cell])


func set_cell_item(world_cell: Vector3i, item: int, orientation: int = 0) -> void:
	var gm: GridMap = _world_owner_gm.get(world_cell, null)
	if gm == null:
		return
	var loc: Vector3i = _world_owner_local[world_cell]
	gm.set_cell_item(loc, item, orientation)


func get_cell_item_basis(world_cell: Vector3i) -> Basis:
	var gm: GridMap = _world_owner_gm.get(world_cell, null)
	if gm == null:
		return Basis.IDENTITY
	return gm.get_cell_item_basis(_world_owner_local[world_cell])


func get_cell_item_orientation(world_cell: Vector3i) -> int:
	var gm: GridMap = _world_owner_gm.get(world_cell, null)
	if gm == null:
		return 0
	return gm.get_cell_item_orientation(_world_owner_local[world_cell])


func is_nav_walkable_cell(cell: Vector3i) -> bool:
	if cell not in used_cells:
		return false
	return _is_walkable(cell)


func is_water_cell(cell: Vector3i) -> bool:
	var tile_flags: TileFlags = cell_flags.get(cell)
	return tile_flags != null and tile_flags.tile_type == TileFlags.TileType.WATER


func is_ice_cell(cell: Vector3i) -> bool:
	var tile_flags: TileFlags = cell_flags.get(cell)
	return tile_flags != null and tile_flags.tile_type == TileFlags.TileType.ICE


func is_land_cell(cell: Vector3i) -> bool:
	return cell in used_cells and _is_walkable(cell) and not is_water_cell(cell)


func is_shoreline_transition(from_cell: Vector3i, to_cell: Vector3i) -> bool:
	return (is_land_cell(from_cell) and is_water_cell(to_cell)) \
	or (is_water_cell(from_cell) and is_land_cell(to_cell))


func cell_blocks_los(cell: Vector3i) -> bool:
	var tile_flags: TileFlags = cell_flags.get(cell)
	return tile_flags != null and tile_flags.is_transparent == false


func _rebuild_world_cell_index() -> void:
	_world_owner_gm.clear()
	_world_owner_local.clear()
	used_cells.clear()
	var seen_world: Dictionary = {}
	for gm: GridMap in _terrain_chunks:
		for local_cell: Vector3i in gm.get_used_cells():
			var wc: Vector3i = gm_translator.local_to_world(local_cell, gm)
			var prev: GridMap = _world_owner_gm.get(wc, null)
			if prev != null and prev != gm:
				push_warning("CombinedGridMap: world cell %s claimed by multiple GridMaps" % wc)
			_world_owner_gm[wc] = gm
			_world_owner_local[wc] = local_cell
			if not seen_world.has(wc):
				seen_world[wc] = true
				used_cells.append(wc)


func _is_water_tile_id(tile_id: int) -> bool:
	return tile_id in WATER_DICT.values()


func _build_cell_flags() -> void:
	cell_flags.clear()
	for cell in used_cells:
		var tile_flags = TileFlags.new()
		tile_flags.elevation = cell.y
		cell_flags[cell] = tile_flags

		if not _is_walkable(cell):
			tile_flags.is_walkable = false

		_mark_cell_tile_flags(cell)

	for key in mesh_flags:
		for cell in get_used_cells_by_item(key):
			cell_flags[cell] = mesh_flags[key]

	for cell in used_cells:
		_mark_cell_tile_flags(cell)


func _mark_cell_tile_flags(cell: Vector3i) -> void:
	var tile_flags: TileFlags = cell_flags.get(cell)
	if tile_flags:
		var tile_id := get_cell_item(cell)
		match tile_id:
			TILE_DICT.STAIRS:
				var orientation := _horizontal_basis_to_step(get_cell_item_basis(cell).x)
				tile_flags.allowed_above_entry_cell = \
				TileFlags.get_allowed_stair_direction_above(cell, orientation)
				tile_flags.allowed_below_entry_cell = \
				TileFlags.get_allowed_stair_direction_below(cell, orientation)
			TILE_DICT.LEDGE:
				var orientation := _get_ledge_drop_direction(cell)
				tile_flags.tile_type = TileFlags.TileType.LEDGE
				tile_flags.ledge_direction = orientation
				var landing_cells := _get_ledge_landing_candidates(cell, orientation)
				if not landing_cells.is_empty():
					tile_flags.ledge_landing_cell = landing_cells[0]
			TILE_DICT.ICE:
				tile_flags.tile_type = TileFlags.TileType.ICE
			_:
				if _is_water_tile_id(tile_id):
					tile_flags.tile_type = TileFlags.TileType.WATER


func _build_graph_edges() -> void:
	graph.clear()
	for cell in used_cells:
		if not _is_walkable(cell):
			continue
		var cell_edges: Array[GraphEdge] = _get_logical_edges(cell)
		graph[cell] = cell_edges


func _get_logical_edges(cell: Vector3i) -> Array[GraphEdge]:
	var edges: Array[GraphEdge] = []
	for dir in [Vector3i.FORWARD, Vector3i.BACK, Vector3i.LEFT, Vector3i.RIGHT]:
		var tf: TileFlags = cell_flags.get(cell)
		if tf and tf.tile_type == TileFlags.TileType.LEDGE and dir == tf.ledge_direction:
			continue
		var target = cell + dir
		var is_neighbor = true if target in used_cells and _is_walkable(target) else false
		if is_neighbor:
			_append_edge_or_ledge_drop(edges, dir, target)
		else:
			var raised_ledge_target: Vector3i = cell + dir + Vector3i.UP
			if raised_ledge_target in used_cells and get_cell_item(raised_ledge_target) == TILE_DICT.LEDGE:
				_append_edge_or_ledge_drop(edges, dir, raised_ledge_target)

	for h_dir in [Vector3i.FORWARD, Vector3i.BACK, Vector3i.LEFT, Vector3i.RIGHT]:
		for v_dir in [Vector3i.UP, Vector3i.DOWN]:
			var target = cell + h_dir + v_dir
			var is_stair = true if target in stairs else false
			if is_stair:
				var tf: TileFlags = cell_flags.get(target)
				if tf:
					if cell == tf.allowed_above_entry_cell or cell == tf.allowed_below_entry_cell:
						_append_edge_or_ledge_drop(edges, h_dir, target)

	if get_cell_item(cell) == TILE_DICT.STAIRS:
		var tf: TileFlags = cell_flags.get(cell)
		if tf:
			var stair_dir := _horizontal_basis_to_step(get_cell_item_basis(cell).x)
			var below: Vector3i = tf.allowed_below_entry_cell
			var above: Vector3i = tf.allowed_above_entry_cell
			if below in used_cells and _is_walkable(below):
				_append_edge_or_ledge_drop(edges, -stair_dir, below)
			if above in used_cells and _is_walkable(above):
				_append_edge_or_ledge_drop(edges, stair_dir, above)

	if get_cell_item(cell) == TILE_DICT.LEDGE:
		var tf: TileFlags = cell_flags.get(cell)
		if tf:
			var ledge_dir := _get_ledge_drop_direction(cell)
			var landing_cells := _get_ledge_landing_candidates(cell, ledge_dir)
			if not landing_cells.is_empty():
				var landing: Vector3i = landing_cells[0]
				tf.ledge_direction = ledge_dir
				tf.ledge_landing_cell = landing
				var ge := GraphEdge.new()
				ge.step = ledge_dir
				ge.to_cell = landing
				ge.move_kind = GraphEdge.MoveKind.LEDGE_JUMP
				ge.via_cell = cell
				edges.append(ge)

	return edges


func _horizontal_basis_to_step(basis_x: Vector3) -> Vector3i:
	var horizontal := Vector3(basis_x.x, 0.0, basis_x.z)
	if horizontal.length_squared() < 0.0001:
		return Vector3i.FORWARD
	horizontal = horizontal.normalized()
	var best: Vector3i = Vector3i.FORWARD
	var best_dot := -INF
	for cardinal in [Vector3i.FORWARD, Vector3i.BACK, Vector3i.LEFT, Vector3i.RIGHT]:
		var d := horizontal.dot(Vector3(cardinal))
		if d > best_dot:
			best_dot = d
			best = cardinal
	return best


func _get_ledge_drop_direction(cell: Vector3i) -> Vector3i:
	return _horizontal_basis_to_step(-get_cell_item_basis(cell).z)


func _get_ledge_landing_candidates(ledge_cell: Vector3i, direction: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for horizontal_distance in range(1, _LEDGE_MAX_HORIZONTAL_SCAN + 1):
		for vertical_drop in range(1, _LEDGE_MAX_VERTICAL_SCAN + 1):
			var candidate := ledge_cell + (direction * horizontal_distance) + (Vector3i.DOWN * vertical_drop)
			if candidate in used_cells and _is_walkable(candidate) and get_cell_item(candidate) != TILE_DICT.LEDGE:
				result.append(candidate)
				return result
	return result


func _append_edge_or_ledge_drop(
		edges: Array[GraphEdge],
		step: Vector3i,
		target: Vector3i,
) -> void:
	var from_cell := target - step
	if get_cell_item(target) == TILE_DICT.LEDGE:
		var ledge_dir := _get_ledge_drop_direction(target)
		if step != ledge_dir:
			return
		var landing_cells := _get_ledge_landing_candidates(target, ledge_dir)
		if landing_cells.is_empty():
			return
		var landing: Vector3i = landing_cells[0]
		var ledge_tf: TileFlags = cell_flags.get(target)
		if ledge_tf:
			ledge_tf.ledge_direction = ledge_dir
			ledge_tf.ledge_landing_cell = landing
		var ledge_edge := GraphEdge.new()
		ledge_edge.step = step
		ledge_edge.to_cell = landing
		ledge_edge.move_kind = GraphEdge.MoveKind.LEDGE_JUMP
		ledge_edge.via_cell = target
		edges.append(ledge_edge)
		return

	var ge := GraphEdge.new()
	ge.step = step
	ge.to_cell = target
	if is_water_cell(from_cell) or is_water_cell(target):
		ge.move_kind = GraphEdge.MoveKind.SURF
	elif is_ice_cell(from_cell) or is_ice_cell(target):
		ge.move_kind = GraphEdge.MoveKind.SLIDE
	edges.append(ge)


func _is_walkable(cell: Vector3i) -> bool:
	var cell_above = cell + Vector3i.UP
	var cell_tile_flags: TileFlags = cell_flags.get(cell)
	var cell_above_tile_flags: TileFlags = cell_flags.get(cell_above)

	if not cell_above_tile_flags and cell_tile_flags:
		return cell_tile_flags.is_walkable

	if cell_above_tile_flags and cell_tile_flags:
		return cell_above_tile_flags.is_passable and cell_tile_flags.is_walkable

	return false


func _animate_water_cells() -> void:
	var max_frame: int = WATER_DICT.size() - 1
	water_frame += water_direction
	if water_frame > max_frame:
		water_frame = max_frame
		water_direction = -1
	elif water_frame < 0:
		water_frame = 0
		water_direction = 1
	var tile_id: int = TILE_DICT.WATER + water_frame
	for cell in water:
		set_cell_item(cell, tile_id, get_cell_item_orientation(cell))


func _collect_water_cells() -> void:
	water.clear()
	for water_tile_id in WATER_DICT.values():
		water.append_array(get_used_cells_by_item(water_tile_id))
