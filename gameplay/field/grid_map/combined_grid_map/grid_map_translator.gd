class_name GridMapTranslator
extends Resource

const CHUNK_SIZE := 64

var _grid_maps: Array[GridMap] = []
var gm_dict: Dictionary = {}


func _init(grid_maps: Array[GridMap]) -> void:
	_grid_maps = grid_maps.duplicate()
	for gm: GridMap in _grid_maps:
		gm_dict[gm] = get_grid_map_chunk(gm)


func get_grid_maps() -> Array[GridMap]:
	return _grid_maps


func get_grid_map_chunk(grid_map: GridMap) -> Vector3i:
	var p := grid_map.global_position
	var chunk_x := int(floor(p.x / float(CHUNK_SIZE)))
	var chunk_y := int(floor(p.y / float(CHUNK_SIZE)))
	var chunk_z := int(floor(p.z / float(CHUNK_SIZE)))
	return Vector3i(chunk_x, chunk_y, chunk_z)


func chunk_origin(chunk: Vector3i) -> Vector3i:
	return Vector3i(
			chunk.x * CHUNK_SIZE,
			chunk.y * CHUNK_SIZE,
			chunk.z * CHUNK_SIZE,
	)


func local_to_world(local_pos: Vector3i, grid_map: GridMap) -> Vector3i:
	var chunk_pos: Vector3i = gm_dict[grid_map]
	var o := chunk_origin(chunk_pos)
	return o + local_pos


func world_cell_to_local_in_grid(world_cell: Vector3i, grid_map: GridMap) -> Vector3i:
	var chunk_pos: Vector3i = gm_dict[grid_map]
	return world_cell - chunk_origin(chunk_pos)
