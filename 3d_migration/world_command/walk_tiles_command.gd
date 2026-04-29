class_name WalkTilesCommand
extends Command

@export var tile_list: Array[DirHelper.Direction] = []


func walk_tiles(character: Character3D) -> bool:
	if tile_list.is_empty():
		return true
	var directions: Array[Vector3i] = []
	for dir: DirHelper.Direction in tile_list:
		directions.append(DirHelper.vec_from_dir(dir))
	return await character.walk_path(directions)


func _trigger_impl(owner) -> Flow:
	if owner is not Character3D:
		return Flow.NEXT
	if await walk_tiles(owner):
		return Flow.NEXT
	return Flow.STOP
