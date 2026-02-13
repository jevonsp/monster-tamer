extends Panel
var processing: bool = false
var text_array: Array[String]
var is_auto_complete: bool = false
var text_index: int
@onready var label: Label = $MarginContainer/Label

func _ready() -> void:
	label.text = ""
	Global.send_overworld_text_box.connect(load_text)
	if visible:
		toggle_visible()


func toggle_visible() -> void:
	visible = !visible


func _unhandled_input(event: InputEvent) -> void:
	if not processing:
		return
	if event.is_action_pressed("yes"):
		advance_text()
		get_viewport().set_input_as_handled()


func load_text(ta: Array[String], auto_complete: bool) -> void:
	Global.toggle_player.emit()
	toggle_visible()
	text_array = ta
	print(text_array)
	is_auto_complete = auto_complete
	if not is_auto_complete:
		processing = true
		print("Processing set to: ", processing)
	text_index = 0
	if text_index <= -1:
		return
	display_text()
	
	
func display_text() -> void:
	label.text = text_array[text_index]
	print(label.text)
	if is_auto_complete:
		await get_tree().create_timer((Global.DEFAULT_DELAY) / 2).timeout
		advance_text()
	
	
func advance_text() -> void:
	text_index += 1
	print(text_index)
	if text_index >= text_array.size():
		text_finished()
	
	
func text_finished() -> void:
	clean_up()
	Global.overworld_text_box_complete.emit()
	
	
func clean_up() -> void:
	toggle_visible()
	label.text = ""
	processing = false
	text_array = []
	is_auto_complete = false
	text_index = 0
	Global.toggle_player.emit()
