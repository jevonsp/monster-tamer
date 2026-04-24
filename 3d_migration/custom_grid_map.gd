class_name CustomGridMap
extends GridMap

const TILE_DICT: Dictionary = {
	STAIRS = 1,
}

@export var mesh_flags: Dictionary[int, TileFlags]

var cell_flags: Dictionary[Vector3i, TileFlags]
var graph: Dictionary[Vector3i, Array] = { }
var used_cells: Array[Vector3i] = []
var stairs: Array[Vector3i] = []


func _ready() -> void:
	stairs = get_used_cells_by_item(TILE_DICT.STAIRS)
	_build_cell_flags()
	_build_graph_edges()

	for n in graph:
		print("node: ", n)
		for e in n:
			print("edge: ", e)


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
		var target = cell + dir
		var is_neighbor = true if target in used_cells and _is_walkable(target) else false
		if is_neighbor:
			var ge := GraphEdge.new()
			ge.step = dir
			ge.to_cell = target
			edges.append(ge)

	for h_dir in [Vector3i.FORWARD, Vector3i.BACK, Vector3i.LEFT, Vector3i.RIGHT]:
		for v_dir in [Vector3i.UP, Vector3i.DOWN]:
			var target = cell + h_dir + v_dir
			var is_stair = true if target in stairs else false
			if is_stair:
				var tf: TileFlags = cell_flags.get(target)
				if tf:
					if cell == tf.allowed_above_entry_cell or cell == tf.allowed_below_entry_cell:
						var ge := GraphEdge.new()
						ge.step = h_dir
						ge.to_cell = target
						edges.append(ge)

	if get_cell_item(cell) == TILE_DICT.STAIRS:
		var tf: TileFlags = cell_flags.get(cell)
		if tf:
			var stair_dir := _horizontal_basis_to_step(get_cell_item_basis(cell).x)
			var below: Vector3i = tf.allowed_below_entry_cell
			var above: Vector3i = tf.allowed_above_entry_cell
			if below in used_cells and _is_walkable(below):
				var ge_below := GraphEdge.new()
				ge_below.step = -stair_dir
				ge_below.to_cell = below
				edges.append(ge_below)
			if above in used_cells and _is_walkable(above):
				var ge_above := GraphEdge.new()
				ge_above.step = stair_dir
				ge_above.to_cell = above
				edges.append(ge_above)

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


func _is_walkable(cell: Vector3i) -> bool:
	var cell_above = cell + Vector3i.UP
	var cell_tile_flags: TileFlags = cell_flags.get(cell)
	var cell_above_tile_flags: TileFlags = cell_flags.get(cell_above)

	if not cell_above_tile_flags and cell_tile_flags:
		return cell_tile_flags.is_walkable

	if cell_above_tile_flags and cell_tile_flags:
		return cell_above_tile_flags.is_passable and cell_tile_flags.is_walkable

	return false
