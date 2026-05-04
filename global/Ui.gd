extends Node

# gdlint:ignore-file:god-class-signals
@warning_ignore_start("unused_signal")
signal switch_ui_context(new_context: Global.AccessFrom)
signal send_text_box(
		object: Node,
		text: Array[String],
		auto_complete: bool,
		is_question: bool,
		toggles_player: bool,
)
signal answer_given(answer: bool)
signal text_box_complete
signal request_open_menu
signal on_menu_closed
signal request_open_party
signal on_party_closed
signal monster_selected(monster: Monster)
signal item_finished_using
signal request_switch_creation(index: int)
signal request_open_inventory
signal on_inventory_closed
signal item_selected(item: Item)
signal set_inventory_use(value: bool)
signal set_inventory_give(value: bool)
signal request_open_summary(monster: Monster)
signal on_summary_closed
signal move_learning_finished
signal request_open_storage
signal request_open_store(store_component)
#signal grab_default_battle_focus
signal update_save_info
signal request_text_entry
signal text_enter_pressed(chosen_string: String)
signal text_cancel_info(can_cancel: bool, message: String)
signal text_cancel_pressed
#signal text_cancel_response(answer: bool)
signal send_choices(question: Array[String], choices: Array[String])
signal choice_given(choice: String)
signal request_open_map


@warning_ignore_restore("unused_signal")
func await_choice(question: Array[String], choices: Array[String]) -> String:
	var wait_state: Dictionary = { "done": false, "choice": "" }
	var _on_pick := func(choice: String) -> void:
		wait_state["choice"] = choice
		wait_state["done"] = true
	choice_given.connect(_on_pick, CONNECT_ONE_SHOT)
	send_choices.emit(question, choices)
	while not wait_state["done"]:
		await get_tree().process_frame
	return wait_state["choice"] as String


func await_text_entry_outcome(
		allow_empty_submit: bool = false,
		max_input_length: int = 0,
) -> Dictionary:
	var te: Node = get_tree().get_first_node_in_group("text_entry_root")
	if te == null:
		push_error("Ui.await_text_entry_outcome: no node in group text_entry_root")
		return { "cancelled": true, "text": "", "failed": true }

	if te.has_method("reset_for_prompt"):
		te.reset_for_prompt()
	te.allow_empty_submit = allow_empty_submit
	te.max_input_length = maxi(0, max_input_length)

	var wait_state: Dictionary = { "done": false, "cancelled": false, "text": "" }

	var _on_enter := func(s: String) -> void:
		wait_state["text"] = s
		wait_state["cancelled"] = false
		wait_state["done"] = true
	var _on_cancel := func() -> void:
		wait_state["cancelled"] = true
		wait_state["text"] = ""
		wait_state["done"] = true

	text_enter_pressed.connect(_on_enter, CONNECT_ONE_SHOT)
	text_cancel_pressed.connect(_on_cancel, CONNECT_ONE_SHOT)

	request_text_entry.emit()

	while not wait_state["done"]:
		await get_tree().process_frame

	return {
		"cancelled": wait_state["cancelled"],
		"text": wait_state["text"],
		"failed": false,
	}
