extends Control

var saved_game: SavedGame

@onready var box_container: BoxContainer = $BoxContainer
@onready var continue_button: Button = $BoxContainer/Continue
@onready var new_game_button: Button = $BoxContainer/NewGame
@onready var erase_save_button: Button = $BoxContainer/EraseSave


func _ready() -> void:
	_prepare_buttons()
	_bind_buttons()


func _prepare_buttons() -> void:
	var buttons = box_container.get_children()
	for b: Button in buttons:
		_toggle_button(b, false)
	_toggle_button(new_game_button, true)
	new_game_button.grab_focus()
	if ResourceLoader.exists("user://savegame.tres"):
		_toggle_button(continue_button, true)
		continue_button.grab_focus()
		_toggle_button(erase_save_button, true)


func _bind_buttons() -> void:
	var buttons = box_container.get_children()
	for b: Button in buttons:
		b.pressed.connect(_on_button_pressed.bind(b))


func _on_button_pressed(button: Button) -> void:
	match button.name:
		"Continue":
			_continue()
		"NewGame":
			_new_game()
		"EraseSave":
			_erase_save()


func _toggle_button(button: Button, is_enabled: bool) -> void:
	button.disabled = not is_enabled
	if is_enabled:
		button.modulate = Color.WHITE
	else:
		button.modulate = Color.TRANSPARENT


func _continue() -> void:
	SaverLoader.load_level(SaverLoader.MAIN)
	SaverLoader.load_game()
	SaverLoader.toggle_visible()
	_close_title_screen()


func _new_game() -> void:
	SaverLoader.load_level(SaverLoader.MAIN)
	SaverLoader.toggle_visible()
	_close_title_screen()


func _erase_save() -> void:
	SaverLoader.erase_saved_game()
	_prepare_buttons()


func _close_title_screen() -> void:
	get_parent().remove_child(self)
	queue_free()
