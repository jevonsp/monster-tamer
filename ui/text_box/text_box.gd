class_name GameTextBox
extends Button

enum LayoutMode { FIELD, BATTLE, EVOLUTION }
enum Phase { LINES, CHOICE_PICK }

const CHOICE_BUTTON = preload("uid://d2u80jaxwyvt7")
const FONT_MAIN_FIELD := preload("res://3p_assets/m3x6.ttf")
const FONT_MAIN_EVOLUTION := preload("res://3p_assets/m5x7.ttf")

var processing: bool = false
var text_array: Array[String] = []
var is_auto_complete: bool = false
var is_question: bool = false
var text_index: int = -1
var _phase: Phase = Phase.LINES
var _layout_mode: LayoutMode = LayoutMode.FIELD
var _hide_after_close: bool = true

@onready var text_box: Button = $"."
@onready var main_label: Label = $MarginContainer/MainLabel
@onready var no_button: Button = $YesNoButtons/No
@onready var yes_button: Button = $YesNoButtons/Yes
@onready var choices_buttons: HBoxContainer = $Choices
@onready var yes_no_buttons: HBoxContainer = $YesNoButtons


func _enter_tree() -> void:
	add_to_group("game_text_box")


func _ready() -> void:
	main_label.text = ""
	choices_buttons.visible = false
	_toggle_questions_visible()
	if visible:
		_toggle_visible()
	text_box.set_focus_mode(Control.FOCUS_ALL)


func _unhandled_input(event: InputEvent) -> void:
	if not processing:
		return
	if _phase == Phase.CHOICE_PICK:
		return
	if is_question and yes_button.visible:
		if event.is_action_pressed("ui_cancel"):
			Ui.answer_given.emit(false)
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("yes") or event.is_action_pressed("no"):
		_advance_text()
		get_viewport().set_input_as_handled()


func bind_ui_signals() -> void:
	if not Ui.send_text_box.is_connected(_load_text):
		Ui.send_text_box.connect(_load_text)
	if not Ui.send_choices.is_connected(_present_choices):
		Ui.send_choices.connect(_present_choices)


func apply_layout_for_mode(mode: LayoutMode) -> void:
	_layout_mode = mode
	match mode:
		LayoutMode.FIELD:
			_hide_after_close = true
			anchor_left = 1.0
			anchor_top = 1.0
			anchor_right = 1.0
			anchor_bottom = 1.0
			offset_left = -688.0
			offset_top = -296.0
			offset_right = -4.0
			offset_bottom = -5.0
			grow_horizontal = Control.GROW_DIRECTION_BEGIN
			grow_vertical = Control.GROW_DIRECTION_BEGIN
			yes_no_buttons.anchor_left = 1.0
			yes_no_buttons.anchor_right = 1.0
			yes_no_buttons.offset_left = -311.0
			yes_no_buttons.offset_top = -98.0
			yes_no_buttons.offset_bottom = -5.0
			main_label.add_theme_font_override("font", FONT_MAIN_FIELD)
		LayoutMode.BATTLE:
			_hide_after_close = true
			anchor_left = 1.0
			anchor_top = 1.0
			anchor_right = 1.0
			anchor_bottom = 1.0
			offset_left = -624.0
			offset_top = -192.0
			offset_right = -20.0
			offset_bottom = -15.0
			grow_horizontal = Control.GROW_DIRECTION_BEGIN
			grow_vertical = Control.GROW_DIRECTION_BEGIN
			yes_no_buttons.anchor_left = 1.0
			yes_no_buttons.anchor_right = 1.0
			yes_no_buttons.offset_left = -311.0
			yes_no_buttons.offset_top = -98.0
			yes_no_buttons.offset_bottom = -5.0
			main_label.add_theme_font_override("font", FONT_MAIN_FIELD)
		LayoutMode.EVOLUTION:
			_hide_after_close = true
			anchor_left = 0.5
			anchor_top = 1.0
			anchor_right = 0.5
			anchor_bottom = 1.0
			offset_left = -304.0
			offset_top = -183.0
			offset_right = 304.0
			offset_bottom = -7.0
			grow_horizontal = Control.GROW_DIRECTION_BOTH
			grow_vertical = Control.GROW_DIRECTION_BEGIN
			yes_no_buttons.anchor_left = 1.0
			yes_no_buttons.anchor_right = 1.0
			yes_no_buttons.offset_left = -311.0
			yes_no_buttons.offset_top = -80.0
			yes_no_buttons.offset_bottom = -5.0
			main_label.add_theme_font_override("font", FONT_MAIN_EVOLUTION)


func clear_text() -> void:
	if yes_button.visible:
		_toggle_questions_visible()
	main_label.text = ""
	text_array = []
	text_index = 0
	is_question = false
	is_auto_complete = false
	processing = false
	_phase = Phase.LINES
	yes_no_buttons.visible = true
	_clear_choice_ui()
	if has_focus():
		release_focus()
	visible = false


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
	if _phase == Phase.CHOICE_PICK:
		return
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
	_clear_choice_ui()
	yes_no_buttons.visible = true
	if yes_button.visible:
		_toggle_questions_visible()
	if _hide_after_close:
		if visible:
			_toggle_visible()
	if text_box.has_focus():
		text_box.release_focus()
	main_label.text = ""
	processing = false
	text_array = []
	text_index = 0
	is_question = false
	is_auto_complete = false
	_phase = Phase.LINES


func _clear_choice_ui() -> void:
	choices_buttons.visible = false
	for child in choices_buttons.get_children():
		choices_buttons.remove_child(child)
		child.queue_free()


func _on_no_pressed() -> void:
	if _phase == Phase.CHOICE_PICK:
		return
	if is_question:
		Ui.answer_given.emit(false)
	else:
		_advance_text()


func _on_yes_pressed() -> void:
	if _phase == Phase.CHOICE_PICK:
		return
	if is_question:
		Ui.answer_given.emit(true)
	else:
		_advance_text()


func _present_choices(question: Array[String], choices: Array[String]) -> void:
	_clear_choice_ui()
	_phase = Phase.CHOICE_PICK
	yes_no_buttons.visible = false
	_create_choices(choices)
	_load_text(null, question, false, false, false)
	choices_buttons.visible = true
	if choices_buttons.get_child_count() > 0:
		var last: Control = choices_buttons.get_child(choices_buttons.get_child_count() - 1) as Control
		last.call_deferred("grab_focus")


func _create_choices(choices: Array[String]) -> void:
	for i in choices.size():
		var new_choice: Button = CHOICE_BUTTON.instantiate()
		choices_buttons.add_child(new_choice)
		new_choice.label.text = choices[i]
		new_choice.pressed.connect(_on_choice_pressed.bind(new_choice))
		new_choice.focus_neighbor_bottom = get_path()


func _on_choice_pressed(button: Button) -> void:
	var c = button.label.text
	Ui.choice_given.emit(c)
	_finish_choice_presentation()


func _finish_choice_presentation() -> void:
	_phase = Phase.LINES
	yes_no_buttons.visible = true
	_clean_up()
	Ui.text_box_complete.emit()
