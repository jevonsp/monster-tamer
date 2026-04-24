extends Control

const INTRO_SEQUENCE = preload("uid://b5hcw5xmokpiu")

@onready var box_container: BoxContainer = $BoxContainer
@onready var continue_button: Button = $BoxContainer/Continue
@onready var new_game_button: Button = $BoxContainer/NewGame
@onready var erase_save_button: Button = $BoxContainer/EraseSave
@onready var game_text_box: GameTextBox = $DialogueCanvas/GameTextBox


func _ready() -> void:
	get_window().grab_focus()
	get_window().size = Vector2i(Global.GAME_WIDTH, Global.GAME_HEIGHT)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	_prepare_buttons()
	_bind_buttons()
	_connect_signals()


func _prepare_buttons() -> void:
	var buttons = box_container.get_children()
	for b: Button in buttons:
		_toggle_button(b, false)
	_toggle_button(new_game_button, true)
	new_game_button.grab_focus()
	if SaverLoader.save_game_exists():
		_toggle_button(continue_button, true)
		continue_button.grab_focus()
		_toggle_button(erase_save_button, true)


func _bind_buttons() -> void:
	var buttons = box_container.get_children()
	for b: Button in buttons:
		b.pressed.connect(_on_button_pressed.bind(b))


func _connect_signals() -> void:
	game_text_box.bind_ui_signals()


func _on_button_pressed(button: Button) -> void:
	match button.name:
		"Continue":
			_continue()
		"NewGame":
			if not SaverLoader.save_game_exists():
				_new_game()
			else:
				await _delete_save_process()
		"EraseSave":
			if SaverLoader.save_game_exists():
				await _delete_save_process()


func _toggle_button(button: Button, is_enabled: bool) -> void:
	button.disabled = not is_enabled
	button.focus_mode = Control.FOCUS_ALL if is_enabled else Control.FOCUS_NONE
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
	var main: Node = SaverLoader.load_level(SaverLoader.MAIN)
	SaverLoader.toggle_visible()
	Global.toggle_player.emit()

	_prep_new_save()

	var intro: Control = INTRO_SEQUENCE.instantiate()
	main.interfaces.add_child(intro)
	intro.play_intro_sequence()
	_close_title_screen()


func _delete_save_process() -> void:
	var ta: Array[String] = ["Are you sure you want to delete your saved game?"]
	Ui.send_text_box.emit(null, ta, false, true, false)
	var answer = await Ui.answer_given
	if answer:
		ta = ["Are you really sure?"]
		Ui.send_text_box.emit(null, ta, false, true, false)
		game_text_box.no_button.call_deferred("grab_focus")
		answer = await Ui.answer_given
		if answer:
			_erase_save()
	erase_save_button.grab_focus()


func _erase_save() -> void:
	Options._reset()
	SaverLoader.erase_saved_game()
	_prepare_buttons()


func _close_title_screen() -> void:
	get_parent().remove_child(self)
	queue_free()


func _prep_new_save() -> void:
	NuzlockeTracker.create_route_tracker()
