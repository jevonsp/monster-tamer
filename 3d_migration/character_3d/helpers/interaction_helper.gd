class_name InteractionHelper
extends Resource

var owner_object: Node3D = null


func _init(oo: Node3D) -> void:
	owner_object = oo


func interact(_player: Player3D) -> void:
	if not owner_object.is_active:
		return
	if owner_object.command_lists.is_empty():
		return
	if owner_object.command_index >= owner_object.command_lists.size():
		return

	PlayerContext3D.toggle_player.emit(false)
	PlayerContext3D.player.clear_inputs()

	var flow: Command.Flow = await owner_object.command_lists[owner_object.command_index].run(owner_object)

	PlayerContext3D.player.clear_inputs()
	PlayerContext3D.toggle_player.emit(true)

	owner_object._after_command_list_run(flow)
