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

	var te: Node = get_tree().get_first_node_in_group("text_entry_root")
	if te == null:
		push_error("NPCTextEntryComponent: no node in group text_entry_root")
		return NPCComponent.Result.CONTINUE
	if te.has_method("reset_for_prompt"):
		te.reset_for_prompt()
	te.allow_empty_submit = allow_empty_submit
	te.max_input_length = maxi(0, max_input_length)

	var wait_state: Dictionary = {"done": false}

	var _on_enter := func(s: String) -> void:
		last_entered_text = s
		last_was_cancelled = false
		wait_state["done"] = true
	var _on_cancel := func() -> void:
		last_was_cancelled = true
		wait_state["done"] = true

	Ui.text_enter_pressed.connect(_on_enter, CONNECT_ONE_SHOT)
	Ui.text_cancel_pressed.connect(_on_cancel, CONNECT_ONE_SHOT)

	Ui.request_text_entry.emit()

	while not wait_state["done"]:
		await get_tree().process_frame

	if last_was_cancelled and terminate_phase_on_cancel:
		return NPCComponent.Result.TERMINATE
	return NPCComponent.Result.CONTINUE
