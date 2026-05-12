class_name GridMapTranslator
extends Resource

const CHUNK_SIZE := 64

var gm_dict: Dictionary[GridMap, Vector3i] = { }


func _init(grid_maps: Array[GridMap]) -> void:
	for gm: GridMap in grid_maps:
		var pos: Vector3i = get_grid_map_chunk(gm)
		gm_dict[gm] = pos

	print("gm_dict:")
	for entry in gm_dict:
		print("%s: %s" % [entry, gm_dict[entry]])
	var used_cells: Array
	for gm: GridMap in gm_dict:
		for cell: Vector3i in gm.get_used_cells():
			used_cells.append(local_to_world(cell, gm))

	used_cells.sort()
	print(used_cells)


func get_grid_map_chunk(grid_map: GridMap) -> Vector3i:
	var chunk_x = int(grid_map.global_position.x / CHUNK_SIZE)
	var chunk_y = int(grid_map.global_position.y / CHUNK_SIZE)
	var chunk_z = int(grid_map.global_position.z / CHUNK_SIZE)
	return Vector3i(chunk_x, chunk_y, chunk_z)


func local_to_world(local_pos: Vector3i, grid_map: GridMap) -> Vector3i:
	var chunk_pos = gm_dict[grid_map]
	var world_x = (chunk_pos.x * CHUNK_SIZE) + local_pos.x
	var world_y = (chunk_pos.y * CHUNK_SIZE) + local_pos.y
	var world_z = (chunk_pos.z * CHUNK_SIZE) + local_pos.z

	return Vector3i(world_x, world_y, world_z)


func world_to_chunk(global_pos: Vector3i) -> Vector3i:
	var chunk_x = floor(global_pos.x / float(CHUNK_SIZE))
	var chunk_y = floor(global_pos.y / float(CHUNK_SIZE))
	var chunk_z = floor(global_pos.z / float(CHUNK_SIZE))
	return Vector3i(chunk_x, chunk_y, chunk_z)


func world_to_local(global_pos: Vector3i) -> Vector3i:
	var chunk_x = global_pos.x % CHUNK_SIZE
	var chunk_y = global_pos.y % CHUNK_SIZE
	var chunk_z = global_pos.z % CHUNK_SIZE
	return Vector3i(chunk_x, chunk_y, chunk_z)
