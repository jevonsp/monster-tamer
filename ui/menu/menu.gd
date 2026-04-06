extends Control

var processing: bool = false
var last_focused_button: Button = null

@onready var interfaces: CanvasLayer = $".."
@onready var save_info_panel: Panel = $Content/SaveInfoPanel


func _ready() -> void:
	_bind_buttons()
	Ui.request_open_menu.connect(_toggle_visible)
	if visible:
		_toggle_visible()


func _input(event: InputEvent) -> void:
	if not processing:
		return
	if event.is_action_pressed("menu") or event.is_action_pressed("no"):
		_close_menu()
		get_viewport().set_input_as_handled()


func _close_menu() -> void:
	_toggle_visible()
	Ui.on_menu_closed.emit()


func _bind_buttons() -> void:
	for button: Button in get_tree().get_nodes_in_group("menu_buttons"):
		button.pressed.connect(_on_menu_pressed.bind(button))
		button.focus_entered.connect(_on_focus_entered.bind(button))


func _on_menu_pressed(button: Button) -> void:
	match button.name:
		"Party":
			_toggle_visible()
			Ui.switch_ui_context.emit(Global.AccessFrom.PARTY)
			Ui.request_open_party.emit()
		"Items":
			_toggle_visible()
			Ui.switch_ui_context.emit(Global.AccessFrom.INVENTORY)
			Ui.request_open_inventory.emit()
		"Save":
			await _start_save_process()
			_focus_default()
		"Options":
			print_debug("Options not yet implemented")


func _on_focus_entered(button: Button) -> void:
	last_focused_button = button
	match last_focused_button.name.to_lower():
		"save":
			_toggle_save_info_panel_visible(true)
		_:
			_toggle_save_info_panel_visible(false)


func _toggle_visible() -> void:
	visible = not visible
	processing = visible
	if visible:
		_focus_default()
		Ui.switch_ui_context.emit(Global.AccessFrom.MENU)
	else:
		last_focused_button = null
		Ui.switch_ui_context.emit(Global.AccessFrom.NONE)


func _toggle_save_info_panel_visible(value: bool) -> void:
	save_info_panel.visible = value
	if save_info_panel.visible:
		save_info_panel.display_info()


func _focus_default() -> void:
	if last_focused_button:
		last_focused_button.grab_focus()
		return
	var buttons = get_tree().get_nodes_in_group("menu_buttons")
	if buttons:
		buttons[0].grab_focus()


func _start_save_process() -> void:
	var text_array: Array[String] = ["Would you like to save the game?"]
	Ui.send_text_box.emit(null, text_array, false, true, false)
	var should_save: bool = await Ui.answer_given
	await Ui.text_box_complete

	if should_save:
		await _finish_save_process()
		return

	_toggle_visible()


func _finish_save_process() -> void:
	SaverLoader.save_game()

	Ui.update_save_info.emit()

	var text_array: Array[String] = ["The game has been saved."]
	Ui.send_text_box.emit(null, text_array, true, false, false)
	await Ui.text_box_complete

	_toggle_visible()
