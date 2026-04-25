class_name CustomGridMap
extends GridMap

const TILE_DICT: Dictionary = {
	STAIRS = 1,
	LEDGE = 15,
}
const _LEDGE_MAX_HORIZONTAL_SCAN := 4
const _LEDGE_MAX_VERTICAL_SCAN := 4

@export var mesh_flags: Dictionary[int, TileFlags]

var cell_flags: Dictionary[Vector3i, TileFlags]
var graph: Dictionary[Vector3i, Array] = { }
var used_cells: Array[Vector3i] = []
var stairs: Array[Vector3i] = []


func _ready() -> void:
	stairs = get_used_cells_by_item(TILE_DICT.STAIRS)
	_build_cell_flags()
	_build_graph_edges()


func is_nav_walkable_cell(cell: Vector3i) -> bool:
	if cell not in used_cells:
		return false
	return _is_walkable(cell)


func _build_cell_flags() -> void:
	used_cells = get_used_cells()
	for cell in used_cells:
		var tile_flags = TileFlags.new()
		tile_flags.elevation = cell.y
		cell_flags[cell] = tile_flags

		if not _is_walkable(cell):
			tile_flags.is_walkable = false

		_mark_cell_tile_flags(cell)

	for key in mesh_flags:
		var cells = get_used_cells_by_item(key)
		for cell in cells:
			cell_flags[cell] = mesh_flags[key]


func _mark_cell_tile_flags(cell: Vector3i) -> void:
	var tile_flags: TileFlags = cell_flags.get(cell)
	if tile_flags:
		match get_cell_item(cell):
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
	target: Vector3i
) -> void:
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
