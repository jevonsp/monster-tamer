extends CanvasLayer
var processing: bool = false
var is_main_menu_open: bool = false

func _ready() -> void:
	_bind_buttons()
	Global.request_open_menu.connect(_toggle_visible)
	if visible:
		_toggle_visible()


func _bind_buttons() -> void:
	for button in get_tree().get_nodes_in_group("menu_buttons"):
		button.pressed.connect(_on_menu_pressed.bind(button))


func _input(event: InputEvent) -> void:
	if not processing:
		return
	if event.is_action_pressed("menu"):
		print("menu pressed")
		_toggle_visible()
		Global.on_menu_closed.emit()
	if is_main_menu_open and event.is_action_pressed("no"):
		print("no pressed")
		_toggle_visible()
		Global.on_menu_closed.emit()


func _on_menu_pressed(button: Button) -> void:
	match button.name:
		"Party":
			print("Party")
		"Items":
			print("Items")
		"Save":
			print("Save")
		"Options":
			print("Options")


func _toggle_visible() -> void:
	print("_toggle_visible")
	visible = !visible
	processing = not processing
	if visible:
		_focus_default()
	is_main_menu_open = visible
		
		
func _focus_default():
	var button: Button = get_tree().get_first_node_in_group("menu_buttons")
	if button:
		button.grab_focus()
