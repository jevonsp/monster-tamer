class_name TextAction
extends Action

@export_multiline() var text: String = "{user} used {action} on {targets}!"
# "{u} ran away from {t}, {u} switched with {t}, {user} used {a} on {t}
@export var is_autocomplete: bool = true
@export var is_question: bool = false


func _before_impl(_owner) -> Flow:
	return Flow.NEXT


func _trigger_impl(owner: BattleChassis) -> Flow:
	var ta: Array[String] = [_format(text, owner)]
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


func _format(string: String, battle_chassis: BattleChassis) -> String:
	var choice = battle_chassis.turn_queue[battle_chassis.turn_index]
	var f = {
		"user": battle_chassis.current_actor,
		"action": choice.action,
		"targets": battle_chassis.targeter.resolve_targets(choice, battle_chassis),
	}
	return string.format(f)
