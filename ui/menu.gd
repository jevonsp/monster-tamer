extends CanvasLayer
var processing: bool = false

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
		get_viewport().set_input_as_handled()
		Global.on_menu_closed.emit()
	if event.is_action_pressed("no"):
		print("no pressed")
		_toggle_visible()
		get_viewport().set_input_as_handled()
		Global.on_menu_closed.emit()


func _on_menu_pressed(button: Button) -> void:
	match button.name:
		"Party":
			Global.request_open_party.emit()
			_toggle_visible()
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

		
func _focus_default():
	print("_focus_default")
	var buttons = get_tree().get_nodes_in_group("menu_buttons")
	if buttons:
		buttons[0].grab_focus()
	for button in buttons:
		if button.has_focus():
			print("%s has focus" % [button])
