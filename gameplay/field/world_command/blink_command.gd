class_name BlinkCommand
extends Command

@export var times: int = 8
@export var duration: float = 0.2


func _trigger_impl(owner: Node) -> Flow:
	await _blink(owner)
	return Flow.NEXT


func _blink(node: Node) -> void:
	var tree = node.get_tree()
	var interval := duration

	for i in times:
		node.visible = !node.visible
		await tree.create_timer(interval).timeout
		interval *= 0.75

	node.visible = false
