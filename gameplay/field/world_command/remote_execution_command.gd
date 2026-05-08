class_name RemoteExecutionCommand
extends Command

@export var obj_path: NodePath


func _trigger_impl(owner: Node) -> Flow:
	var obj: Node
	if not obj_path:
		obj = owner
	else:
		obj = owner.get_node(obj_path)

	if not obj:
		return Flow.STOP

	await obj.interaction_helper.interact(PlayerContext3D.player)

	return Flow.NEXT
