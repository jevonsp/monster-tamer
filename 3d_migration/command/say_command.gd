class_name SayCommand
extends Command

@export_multiline() var text: Array[String] = []
@export var is_autocomplete: bool = false


func _trigger_impl(_owner: Node) -> Flow:
	Ui.send_text_box.emit(null, text, is_autocomplete, false, false)
	await Ui.text_box_complete
	return Flow.NEXT
