class_name ChangeIndexCommand
extends Command

@export var obj_path: NodePath
@export var index: int


func _trigger_impl(owner: Node) -> Flow:
	var obj: Node
	if not obj_path:
		obj = owner
	else:
		obj = owner.get_node(obj_path)

	if not obj:
		return Flow.STOP

	if index >= obj.command_lists.size():
		return Flow.STOP

	if obj.has_method("change_command_index_to"):
		print("changing %s idx to %s" % [obj, index])
		obj.change_command_index_to(index)

	return Flow.NEXT
