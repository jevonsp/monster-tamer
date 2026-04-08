class_name NPCTextEntryComponent
extends NPCComponent

@export_multiline var prompt_lines: Array[String] = []
@export var allow_empty_submit: bool = false
@export var max_input_length: int = 0
@export var terminate_phase_on_cancel: bool = false

var last_entered_text: String = ""
var last_was_cancelled: bool = false


func trigger(obj: Node) -> NPCComponent.Result:
	if not obj.is_in_group("player"):
		return NPCComponent.Result.CONTINUE

	last_entered_text = ""
	last_was_cancelled = false

	if not prompt_lines.is_empty():
		Ui.send_text_box.emit(null, prompt_lines, true, false, false)
		await Ui.text_box_complete

	var outcome: Dictionary = await Ui.await_text_entry_outcome(allow_empty_submit, max_input_length)
	last_entered_text = outcome.get("text", "") as String
	last_was_cancelled = outcome.get("cancelled", false) as bool
	if outcome.get("failed", false):
		return NPCComponent.Result.CONTINUE

	if last_was_cancelled and terminate_phase_on_cancel:
		return NPCComponent.Result.TERMINATE
	return NPCComponent.Result.CONTINUE
