class_name InteractionRunner
extends RefCounted


func interact(owner: Node, player: Player3D) -> void:
	if not owner.is_active:
		return
	if owner.command_lists.is_empty():
		return
	if owner.command_index >= owner.command_lists.size():
		return

	PlayerContext3D.toggle_player.emit(false)
	PlayerContext3D.player.clear_inputs()

	var flow: Command.Flow = await owner.command_lists[owner.command_index].run(self)

	PlayerContext3D.player.clear_inputs()
	PlayerContext3D.toggle_player.emit(true)

	_after_command_list_run(flow)


func change_command_index_to(owner: Node, index: int) -> void:
	if index > owner.command_lists.size():
		return

	owner.command_index = index


func _after_command_list_run(_flow: Command.Flow) -> void:
	pass


func _update_owner(owner: Node) -> void:
	owner._masks_player = owner._is_active
	owner.visible = owner._is_active
	if owner._blocks_player:
		owner.collision_layer = 3
	else:
		owner.collision_layer = 0
	if owner._masks_player:
		owner.collision_mask = 2
	else:
		owner.collision_mask = 0
