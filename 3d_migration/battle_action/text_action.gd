class_name TextAction
extends Action

@export_multiline() var text: String = "{user} used {action} on {targets}!"
# "{u} ran away from {t}, {u} switched with {t}, {user} used {a} on {t}
@export var is_autocomplete: bool = true
@export var is_question: bool = false


func _before_impl(_owner) -> Flow:
	return Flow.NEXT


func _trigger_impl(owner: BattleChassis) -> Flow:
	var ta: Array[String] = [text]
	Ui.send_text_box.emit(null, ta, is_autocomplete, is_question, false)

	if is_question:
		var answer = await Ui.answer_given
		if answer:
			return Flow.NEXT
		return Flow.SKIP

	await Ui.text_box_complete
	return Flow.NEXT


func _after_impl(_owner) -> Flow:
	return Flow.NEXT


func _parse_text(owner: BattleChassis) -> void:
	var choice: Choice = owner.turn_queue[owner.turn_index]
	match choice.type:
		Choice.Type.MOVE:
			return _parse_move(owner)
		Choice.Type.ITEM:
			return _parse_item()
		Choice.Type.SWITCH:
			return _parse_switch()
		Choice.Type.FLEE:
			return _parse_flee()


func _parse_move(owner: BattleChassis) -> void:
	pass


func _parse_item() -> void:
	pass


func _parse_switch() -> void:
	pass


func _parse_flee() -> void:
	pass
