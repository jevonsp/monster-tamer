class_name SayCommand
extends Command

@export_multiline() var text: Array[String] = []
@export var is_autocomplete: bool = false
@export var is_question: bool = false


func _trigger_impl(_owner: Node) -> Flow:
	Ui.send_text_box.emit(null, _format_text(), is_autocomplete, is_question, false)
	if is_question:
		var answer = await Ui.answer_given
		await Ui.text_box_complete
		if answer:
			return Flow.NEXT
		return Flow.STOP
	await Ui.text_box_complete
	return Flow.NEXT


func _format_text() -> Array[String]:
	var fmt: Array[String] = []
	for i in text.size():
		fmt.append(
			text[i].format(
				{
					"player_name": PlayerContext3D.player_info_handler.player_name,
				},
			),
		)
	return fmt
