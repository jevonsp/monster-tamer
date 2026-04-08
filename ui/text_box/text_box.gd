extends Panel

const CHOICE_BUTTON = preload("uid://d2u80jaxwyvt7")

@export var in_battle_text_box: bool = false
@export var ignore_player_battle_state: bool = false
@export var skip_if_parent_control_invisible: bool = false

var processing: bool = false
var text_array: Array[String] = []
var is_auto_complete: bool = false
var is_question: bool = false
var text_index: int = -1

@onready var text_box: Panel = $"."
@onready var main_label: Label = $MarginContainer/MainLabel
@onready var no_button: Button = $YesNoButtons/No
@onready var yes_button: Button = $YesNoButtons/Yes
@onready var choices_buttons: HBoxContainer = $Choices
@onready var yes_no_buttons: HBoxContainer = $YesNoButtons


func _ready() -> void:
	_connect_signals()
	main_label.text = ""
	_toggle_questions_visible()
	if not in_battle_text_box and visible:
		_toggle_visible()
	text_box.set_focus_mode(Control.FOCUS_ALL)


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


func clear_text() -> void:
	if yes_button.visible:
		_toggle_questions_visible()
	main_label.text = ""
	text_array = []
	text_index = 0
	is_question = false
	is_auto_complete = false
	processing = false


func _connect_signals() -> void:
	Ui.send_text_box.connect(_load_text)
	Ui.send_choices.connect(_present_choices)


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
	if skip_if_parent_control_invisible:
		var par: Node = get_parent()
		if par is Control and not (par as Control).visible:
			return
	var interfaces := get_tree().get_root().find_child("Interfaces", true, false)
	var in_battle_ui: bool = \
	interfaces != null and interfaces.ui_context == Global.AccessFrom.BATTLE
	if not in_battle_text_box and in_battle_ui:
		main_label.text = ""
		processing = false
		return
	if not ignore_player_battle_state and in_battle_text_box and not in_battle_ui:
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
		if choices_buttons.visible and choices_buttons.get_child_count() > 0:
			return
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
	if is_question:
		Ui.answer_given.emit(false)
	else:
		_advance_text()


func _on_yes_pressed() -> void:
	if is_question:
		Ui.answer_given.emit(true)
	else:
		_advance_text()


func _present_choices(question: Array[String], choices: Array[String]) -> void:
	for c in choices_buttons.get_children():
		choices_buttons.remove_child(c)
		c.queue_free()
	yes_no_buttons.visible = false
	_create_choices(choices)
	_load_text(null, question, false, false, false)
	choices_buttons.visible = true
	if choices_buttons.get_child_count() > 0:
		var last: Control = choices_buttons.get_child(choices_buttons.get_child_count() - 1) as Control
		last.call_deferred("grab_focus")
	var after_choice := func(_choice: String) -> void:
		choices_buttons.visible = false
		yes_no_buttons.visible = true
		for child in choices_buttons.get_children():
			child.queue_free()
		_text_finished()
	Ui.choice_given.connect(after_choice, CONNECT_ONE_SHOT)


func _create_choices(choices: Array[String]) -> void:
	for i in choices.size():
		var new_choice: Button = CHOICE_BUTTON.instantiate()
		choices_buttons.add_child(new_choice)
		new_choice.label.text = choices[i]
		new_choice.pressed.connect(_on_choice_pressed.bind(new_choice))
		new_choice.focus_neighbor_bottom = get_path()


func _on_choice_pressed(button: Button) -> void:
	var choice = button.label.text
	Ui.choice_given.emit(choice)
