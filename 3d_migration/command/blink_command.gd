class_name BlinkCommand
extends Command

@export var times: int = 4
@export var duration: float = 0.4


func _trigger_impl(owner: Node) -> Flow:
	await _blink(owner)
	return Flow.NEXT


func _blink(owner: Node) -> void:
	var sprite = owner.get_node_or_null("Sprite3D")
	if not sprite:
		return

	var tree = owner.get_tree()
	var tween = tree.create_tween()

	var d = duration

	for i in times:
		tween.tween_property(sprite, "modulate:a", 0.0, d)
		await tween.finished
		tween.tween_property(sprite, "modulate:a", 1.0, d)
		await tween.finished
		d *= 0.5
