class_name BlinkCommand
extends Command

@export var times: int = 4
@export var duration: float = 0.4


func _trigger_impl(owner: Node) -> Flow:
	await _blink(owner)
	return Flow.NEXT


func _blink(owner: Node) -> void:
	print("blink")
