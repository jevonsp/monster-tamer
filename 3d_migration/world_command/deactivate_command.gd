class_name DeactivateCommand
extends Command


func _trigger_impl(owner: Node) -> Flow:
	(owner as CellObject).deactivate()

	return Flow.NEXT
