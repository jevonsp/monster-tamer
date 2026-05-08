class_name LookCommand
extends Command

@export var look_list: Array[DirHelper.Direction] = []


func look_dirs(character: Character3D) -> bool:
	if look_list.is_empty():
		return true
	var directions: Array[Vector3i] = []
	for dir: DirHelper.Direction in look_list:
		var dir_helper = DirHelper.new()
		directions.append(dir_helper.vec_from_dir(dir))
	return await character.look_directions(directions)


func _trigger_impl(owner) -> Flow:
	if owner is not Character3D:
		return Flow.NEXT
	if await look_dirs(owner):
		return Flow.NEXT
	return Flow.STOP
