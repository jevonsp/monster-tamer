extends Control
var processing: bool = false
var last_focused_button: Button = null
var should_save_game: bool = false
@onready var interfaces: CanvasLayer = $".."

func _ready() -> void:
	_bind_buttons()
	Global.request_open_menu.connect(_toggle_visible)
	if visible:
		_toggle_visible()


func _bind_buttons() -> void:
	for button: Button in get_tree().get_nodes_in_group("menu_buttons"):
		button.pressed.connect(_on_menu_pressed.bind(button))
		button.focus_entered.connect(_on_focus_entered.bind(button))


func _unhandled_input(event: InputEvent) -> void:
	if not processing:
		return
	if event.is_action_pressed("menu"):
		_toggle_visible()
		get_viewport().set_input_as_handled()
		Global.on_menu_closed.emit()
	if event.is_action_pressed("no"):
		_toggle_visible()
		get_viewport().set_input_as_handled()
		Global.on_menu_closed.emit()


func _on_menu_pressed(button: Button) -> void:
	match button.name:
		"Party":
			_toggle_visible()
			Global.switch_ui_context.emit(Global.AccessFrom.PARTY)
			Global.request_open_party.emit()
		"Items":
			_toggle_visible()
			Global.switch_ui_context.emit(Global.AccessFrom.INVENTORY)
			Global.request_open_inventory.emit()
		"Save":
			await _start_save_process()
			_focus_default()
		"Options":
			print_debug("Options not yet implemented")


func _on_focus_entered(button: Button) -> void:
	last_focused_button = button


func _toggle_visible() -> void:
	visible = not visible
	processing = not processing
	if visible:
		_focus_default()
		Global.switch_ui_context.emit(Global.AccessFrom.MENU)
	else:
		last_focused_button = null
		Global.switch_ui_context.emit(Global.AccessFrom.NONE)


func _focus_default() -> void:
	if last_focused_button:
		last_focused_button.grab_focus()
		return
	var buttons = get_tree().get_nodes_in_group("menu_buttons")
	if buttons:
		buttons[0].grab_focus()


func _start_save_process() -> void:
	var text_array: Array[String] = ["Would you like to save the game?"]
	Global.send_text_box.emit(self, text_array, false, true, false)
	await Global.text_box_complete
	if should_save_game:
		_finish_save_process()
	should_save_game = false


func _finish_save_process() -> void:
	SaverLoader.save_game()


func trigger() -> void:
	should_save_game = true
