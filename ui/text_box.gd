extends Panel
@export var in_battle_text_box: bool = false
var processing: bool = false
var text_array: Array[String] = []
var is_auto_complete: bool = false
var is_question: bool = false
var toggles_player: bool = false
var text_index: int = -1
var obj_ref: Node = null
@onready var text_box: Panel = $"."
@onready var main_label: Label = $MarginContainer/MainLabel
@onready var no_button: Button = $HBoxContainer/No
@onready var yes_button: Button = $HBoxContainer/Yes


func _ready() -> void:
	main_label.text = ""
	Global.send_text_box.connect(_load_text)
	_toggle_questions_visible()
	if not in_battle_text_box and visible:
		_toggle_visible()

	yes_button.gui_input.connect(_on_button_gui_input.bind(yes_button))
	no_button.gui_input.connect(_on_button_gui_input.bind(no_button))


func _unhandled_input(event: InputEvent) -> void:
	if not processing:
		return
	if is_question and yes_button.visible:
		return
	if event.is_action_pressed("yes") or event.is_action_pressed("no"):
		_advance_text()
		get_viewport().set_input_as_handled()


func _on_button_gui_input(event: InputEvent, _button: Button) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()


func _toggle_visible() -> void:
	visible = not visible


func _toggle_questions_visible() -> void:
	no_button.visible = not yes_button.visible
	yes_button.visible = not yes_button.visible
	if yes_button.visible:
		yes_button.grab_focus()
	else:
		for button in [no_button, yes_button]:
			if button.has_focus():
				button.release_focus()


func _load_text(
	obj: Node, ta: Array[String], auto_complete: bool, question: bool, toggle: bool
		) -> void:
	print_debug("TEXT: load in_battle=%s visible=%s auto=%s question=%s toggle_player=%s lines=%s obj=%s" \
			% [in_battle_text_box, visible, auto_complete, question, toggle, ta.size(), obj])
	if not in_battle_text_box and Player.in_battle:
		return
	if in_battle_text_box and not Player.in_battle:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player.processing:
		Global.toggle_player.emit()
	if not visible:
		_toggle_visible()
	obj_ref = obj
	is_question = question
	text_array = ta
	is_auto_complete = auto_complete
	toggles_player = toggle
	if not is_auto_complete:
		processing = true
	text_index = 0
	if text_index <= -1:
		return
	_display_text()


func _display_text() -> void:
	text_box.grab_focus()
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
	var answer = await Global.answer_given
	if answer:
		return true
	return false


func _trigger() -> void:
	if obj_ref.has_method("trigger"):
		obj_ref.trigger()


func _text_finished() -> void:
	print_debug("TEXT: finished in_battle=%s lines=%s question=%s auto=%s" \
			% [in_battle_text_box, text_array.size(), is_question, is_auto_complete])
	_clean_up()
	Global.text_box_complete.emit()


func _clean_up() -> void:
	if yes_button.visible:
		_toggle_questions_visible()
	if not in_battle_text_box:
		_toggle_visible()
	if text_box.has_focus():
		text_box.release_focus()
	main_label.text = ""
	processing = false
	obj_ref = null
	text_array = []
	text_index = 0
	is_question = false
	is_auto_complete = false
	if toggles_player:
		Global.toggle_player.emit()
	toggles_player = false


func _on_no_pressed() -> void:
	Global.answer_given.emit(false)


func _on_yes_pressed() -> void:
	Global.answer_given.emit(true)
