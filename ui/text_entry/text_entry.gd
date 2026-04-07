extends Control

signal enter_pressed(chosen_string: String)

var processing: bool = false
var string: String = "":
	set(value):
		string = value
		_display_string()
var last_focused_button: Button = null
var last_focused_group: GridContainer = null

@onready var capitals: GridContainer = $Capitals
@onready var lowercase: GridContainer = $Lowercase
@onready var special: GridContainer = $Special
@onready var numbers: GridContainer = $Numbers
@onready var label: Label = $Panel/Label


func _ready() -> void:
	_connect_signals()
	lowercase.get_child(0).grab_focus()


func _input(event: InputEvent) -> void:
	if not processing:
		return
	if event.is_action_pressed("no"):
		_remove_character()
	if event.is_action_pressed("start"):
		_enter()


func _connect_signals() -> void:
	var buttons = get_tree().get_nodes_in_group("text_entry_buttons")
	for button: Button in buttons:
		button.button_clicked.connect(_on_button_clicked)
		button.focus_entered_info.connect(_on_focus_entered)


func _toggle_visible() -> void:
	capitals.visible = false
	lowercase.visible = true
	special.visibile = false
	numbers.visible = true

	visible = not visible
	processing = visible


func _on_button_clicked(chr: String, is_special: bool, act: TextEntryButton.Action) -> void:
	if not is_special:
		_add_character(chr)
	else:
		match act:
			TextEntryButton.Action.DELETE:
				_remove_character()
			TextEntryButton.Action.SHIFT:
				_shift_characters()
			TextEntryButton.Action.CANCEL:
				_cancel()
			TextEntryButton.Action.ENTER:
				_enter()
			_:
				pass


func _on_focus_entered(button: Button, grid_container: GridContainer) -> void:
	last_focused_button = button
	last_focused_group = grid_container


func _add_character(chr: String) -> void:
	string += chr


func _remove_character() -> void:
	if string.length() > 0:
		string = string.erase(string.length() - 1, 1)


func _display_string() -> void:
	label.text = string


func _shift_characters() -> void:
	var containers = [capitals, lowercase, special, numbers]
	for container in containers:
		container.visible = not container.visible
	_refocus_shift_button()


func _refocus_shift_button() -> void:
	const SHIFT_BUTTON := "TextEntryButton10"
	if capitals.visible and capitals.has_node(SHIFT_BUTTON):
		capitals.get_node(SHIFT_BUTTON).grab_focus()
	elif lowercase.visible and lowercase.has_node(SHIFT_BUTTON):
		lowercase.get_node(SHIFT_BUTTON).grab_focus()


func _cancel() -> void:
	processing = false

	var ta: Array[String] = ["Are you sure you want to cancel?"]
	Ui.send_text_box.emit(null, ta, false, true, false)
	var answer = await Ui.answer_given

	if answer:
		_toggle_visible()
	else:
		processing = true


func _enter() -> void:
	if string.length() > 0:
		enter_pressed.emit(string)
