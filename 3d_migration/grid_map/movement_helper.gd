class_name MovementHelper
extends Resource

var used_cells: Array[Vector3i] = []

const GROUND_SCAN_MIN_Y := -32

func get_cell_at_world(world_position: Vector3, grid_map: CustomGridMap) -> Vector3i:
	return grid_map.local_to_map(grid_map.to_local(world_position))


func get_ground_cell(
	world_position: Vector3, grid_map: CustomGridMap, origin_to_cell_floor_offset: Vector3 = Vector3(0.5, 2.1, 0.2)
) -> Vector3i:
	var foot_world := world_position - origin_to_cell_floor_offset
	var cell := get_cell_at_world(foot_world, grid_map)
	while cell.y >= GROUND_SCAN_MIN_Y:
		if cell in used_cells and grid_map.is_nav_walkable_cell(cell):
			return cell
		cell += Vector3i.DOWN
	var col := get_cell_at_world(foot_world, grid_map)
	var best: Vector3i = col
	var best_y: int = GROUND_SCAN_MIN_Y - 1
	for c: Vector3i in used_cells:
		if c.x != col.x or c.z != col.z:
			continue
		if not grid_map.is_nav_walkable_cell(c):
			continue
		if c.y > best_y:
			best_y = c.y
			best = c
	if best_y >= GROUND_SCAN_MIN_Y:
		return best
	return get_cell_at_world(foot_world, grid_map)


func get_item_at_cell(cell: Vector3i, grid_map: CustomGridMap) -> int:
	return grid_map.get_cell_item(cell)


func get_elevation(world_position: Vector3, grid_map: CustomGridMap) -> int:
	return get_ground_cell(world_position, grid_map).y
