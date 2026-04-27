class_name SayCommand
extends Command

@export_multiline() var text: Array[String] = []
@export var is_autocomplete: bool = false
@export var is_question: bool = false

func _trigger_impl(_owner: Node) -> Flow:
	Ui.send_text_box.emit(null, text, is_autocomplete, is_question, false)
	if is_question:
		var answer = await Ui.answer_given
		await Ui.text_box_complete
		if answer:
			return Flow.NEXT
		else:
			return Flow.STOP
	await Ui.text_box_complete
	return Flow.NEXT
