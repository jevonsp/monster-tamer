extends Panel

@export var in_battle_text_box: bool = false

var processing: bool = false
var text_array: Array[String] = []
var is_auto_complete: bool = false
var is_question: bool = false
var text_index: int = -1

@onready var text_box: Panel = $"."
@onready var main_label: Label = $MarginContainer/MainLabel
@onready var no_button: Button = $HBoxContainer/No
@onready var yes_button: Button = $HBoxContainer/Yes


func _ready() -> void:
	main_label.text = ""
	Ui.send_text_box.connect(_load_text)
	_toggle_questions_visible()
	if not in_battle_text_box and visible:
		_toggle_visible()


func _unhandled_input(event: InputEvent) -> void:
	if not processing:
		return
	if is_question and yes_button.visible:
		if event.is_action_pressed("ui_cancel"):
			Ui.answer_given.emit(false)
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("yes") or event.is_action_pressed("no"):
		_advance_text()
		get_viewport().set_input_as_handled()


func _toggle_visible() -> void:
	visible = not visible


func _toggle_questions_visible() -> void:
	no_button.visible = not yes_button.visible
	yes_button.visible = not yes_button.visible
	if yes_button.visible:
		call_deferred("_focus_question_button")
	else:
		for button in [no_button, yes_button]:
			if button.has_focus():
				button.release_focus()


func _focus_question_button() -> void:
	if yes_button.visible:
		yes_button.grab_focus()


func _load_text(
		_obj: Node,
		ta: Array[String],
		auto_complete: bool,
		question: bool,
		_toggle: bool,
) -> void:
	if not in_battle_text_box and Player.in_battle:
		return
	if in_battle_text_box and not Player.in_battle:
		return
	if not visible:
		_toggle_visible()
	is_question = question
	text_array = ta
	is_auto_complete = auto_complete
	if not is_auto_complete:
		processing = true
	text_index = 0
	if text_index <= -1:
		return
	_display_text()


func _display_text() -> void:
	call_deferred("_focus_text_box")
	main_label.text = text_array[text_index]
	if is_question:
		if text_array.size() - text_index == 1:
			_advance_text()
	if is_auto_complete:
		await get_tree().create_timer((Global.DEFAULT_DELAY) / 2).timeout
		_advance_text()


func _focus_text_box() -> void:
	if visible and not is_question:
		text_box.grab_focus()


func _advance_text() -> void:
	text_index += 1
	if text_index >= text_array.size():
		if not is_question:
			_text_finished()
			return
		else:
			await _await_question()
	_text_finished()


func _await_question() -> void:
	_toggle_questions_visible()
	await Ui.answer_given


func _text_finished() -> void:
	_clean_up()
	call_deferred("_emit_text_box_complete")


func _emit_text_box_complete() -> void:
	Ui.text_box_complete.emit()


func _clean_up() -> void:
	if yes_button.visible:
		_toggle_questions_visible()
	if not in_battle_text_box:
		_toggle_visible()
	if text_box.has_focus():
		text_box.release_focus()
	main_label.text = ""
	processing = false
	text_array = []
	text_index = 0
	is_question = false
	is_auto_complete = false


func _on_no_pressed() -> void:
	Ui.answer_given.emit(false)


func _on_yes_pressed() -> void:
	Ui.answer_given.emit(true)


func _move_to_evolution_spot() -> void:
	if not in_battle_text_box:
		return


func _move_back() -> void:
	pass
