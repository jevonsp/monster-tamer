extends Control
signal answer_given(answer: bool)
var processing: bool = false
var text_array: Array[String]
var is_auto_complete: bool = false
var is_question: bool = false
var text_index: int
var obj_ref: Node
@onready var main_label: Label = $Panel/MarginContainer/Label
@onready var no_button: Button = $Panel/HBoxContainer/No
@onready var yes_button: Button = $Panel/HBoxContainer/Yes


func _ready() -> void:
	main_label.text = ""
	Global.send_overworld_text_box.connect(_load_text)

	_toggle_questions_visible()
	if visible:
		_toggle_visible()
		
	yes_button.gui_input.connect(_on_button_gui_input.bind(yes_button))
	no_button.gui_input.connect(_on_button_gui_input.bind(no_button))
	
	
func _unhandled_input(event: InputEvent) -> void:
	if not processing:
		return
	if is_question and yes_button.visible:
		return
	if event.is_action_pressed("yes"):
		_advance_text()
		get_viewport().set_input_as_handled()


func _on_button_gui_input(event: InputEvent, _button: Button) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()


func _toggle_visible() -> void:
	visible = !visible


func _toggle_questions_visible() -> void:
	no_button.visible = !yes_button.visible
	yes_button.visible = !yes_button.visible
	if yes_button.visible:
		yes_button.grab_focus()
	else:
		for button in [no_button, yes_button]:
			if button.has_focus():
				button.release_focus()


func _load_text(obj: Node, ta: Array[String], auto_complete: bool, question: bool) -> void:
	Global.toggle_player.emit()
	_toggle_visible()
	obj_ref = obj
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
	main_label.text = text_array[text_index]
	if is_question:
		if text_array.size() - text_index == 1:
			_advance_text()
	if is_auto_complete:
		await get_tree().create_timer((Global.DEFAULT_DELAY) / 2).timeout
		_advance_text()
	
	
func _advance_text() -> void:
	text_index += 1
	if text_index >= text_array.size():
		if not is_question:
			_text_finished()
			return
		else:
			if await _await_question():
				_trigger()
	_text_finished()
	
	
func _await_question() -> bool:
	_toggle_questions_visible()
	var answer = await answer_given
	if answer:
		return true
	return false
	
	
func _trigger() -> void:
	if obj_ref.has_method("trigger"):
		obj_ref.trigger()
	
	
func _text_finished() -> void:
	_clean_up()
	Global.overworld_text_box_complete.emit()
	
	
func _clean_up() -> void:
	if yes_button.visible:
		_toggle_questions_visible()
	_toggle_visible()
	main_label.text = ""
	processing = false
	text_array = []
	is_question = false
	is_auto_complete = false
	obj_ref = null
	text_index = 0
	Global.toggle_player.emit()


func _on_no_pressed() -> void:
	answer_given.emit(false)


func _on_yes_pressed() -> void:
	answer_given.emit(true)
