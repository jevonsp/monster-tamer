extends Panel
signal answer_given(answer: bool)
var processing: bool = false
var text_array: Array[String]
var is_auto_complete: bool = false
var is_question: bool = false
var text_index: int
@onready var main_label: Label = $MarginContainer/Label
@onready var no_button: Button = $HBoxContainer/No
@onready var yes_button: Button = $HBoxContainer/Yes

func _ready() -> void:
	main_label.text = ""
	Global.send_overworld_text_box.connect(load_text)

	toggle_questions_visible()
	if visible:
		toggle_visible()


func toggle_visible() -> void:
	visible = !visible


func toggle_questions_visible() -> void:
	no_button.visible = !yes_button.visible
	yes_button.visible = !yes_button.visible
	if yes_button.visible:
		yes_button.grab_focus()
	else:
		for button in [no_button, yes_button]:
			if button.has_focus():
				button.release_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not processing:
		return
	if is_question and yes_button.visible:
		return
	if event.is_action_pressed("yes"):
		advance_text()
		get_viewport().set_input_as_handled()


func load_text(ta: Array[String], auto_complete: bool, question: bool) -> void:
	Global.toggle_player.emit()
	toggle_visible()
	is_question = question
	print("got is_question:", is_question)
	text_array = ta
	is_auto_complete = auto_complete
	if not is_auto_complete:
		processing = true
	text_index = 0
	if text_index <= -1:
		return
	display_text()
	
	
func display_text() -> void:
	main_label.text = text_array[text_index]
	if is_question:
		if text_array.size() - text_index == 1:
			advance_text()
	if is_auto_complete:
		await get_tree().create_timer((Global.DEFAULT_DELAY) / 2).timeout
		advance_text()
	
	
func advance_text() -> void:
	text_index += 1
	if text_index >= text_array.size():
		if not is_question:
			text_finished()
			return
		else:
			if await await_question():
				trigger()
	text_finished()
	
	
func await_question() -> bool:
	toggle_questions_visible()
	var answer = await answer_given
	if answer:
		return true
	return false
	
	
func trigger() -> void:
	print("would trigger here")
	
	
func text_finished() -> void:
	clean_up()
	Global.overworld_text_box_complete.emit()
	
	
func clean_up() -> void:
	toggle_questions_visible()
	toggle_visible()
	main_label.text = ""
	processing = false
	text_array = []
	is_question = false
	is_auto_complete = false
	text_index = 0
	Global.toggle_player.emit()


func _on_no_pressed() -> void:
	print("no")
	answer_given.emit(false)


func _on_yes_pressed() -> void:
	print("yes")
	answer_given.emit(true)
