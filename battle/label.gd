extends Label
var processing: bool = false
var text_array: Array[String]
var is_auto_complete: bool = false
var text_index: int = 0

func _ready() -> void:
	text = ""
	Global.send_text_box.connect(load_text)


func _unhandled_input(event: InputEvent) -> void:
	if not processing:
		return
	if event.is_action_pressed("yes"):
		advance_text()
		get_viewport().set_input_as_handled()


func load_text(ta: Array[String], auto_complete: bool) -> void:
	text_array = ta
	is_auto_complete = auto_complete
	if not is_auto_complete:
		processing = true
	text_index = text_array.size() - 1
	if text_index <= -1:
		return
	display_text()
	
	
func display_text() -> void:
	text = text_array[text_index]
	if is_auto_complete:
		await get_tree().create_timer(Global.DEFAULT_DELAY).timeout
		advance_text()
	
	
func advance_text() -> void:
	text_index += 1
	if text_index >= text_array.size() - 1:
		text_finished()
	
	
func text_finished() -> void:
	print_debug("Text finished")
	Global.text_box_complete.emit()
	clean_up()
	
	
func clean_up() -> void:
	text = ""
	processing = false
	text_array = []
	is_auto_complete = false
	text_index = 0
