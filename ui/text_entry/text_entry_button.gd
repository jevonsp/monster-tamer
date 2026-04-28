@tool
class_name TextEntryButton
extends Button

signal button_clicked(from_button: TextEntryButton, chr: String, is_special: bool, act: ButtonType)
signal focus_entered_info(button: Button, grid_container: GridContainer)

enum ButtonType { NONE, DELETE, SHIFT, CANCEL, ENTER }

@export var character: String:
	set(value):
		character = value
		_set_label()
@export var is_special: bool = false
@export var action: ButtonType = ButtonType.NONE

@onready var label: Label = $Label


func _ready() -> void:
	if Engine.is_editor_hint():
		_set_label()
		return
	_set_label()
	_connect_signals()


func _connect_signals() -> void:
	self.pressed.connect(_on_pressed)
	self.focus_entered.connect(_on_focus_entered)


func _set_label() -> void:
	if label:
		label.text = character


func _on_pressed() -> void:
	button_clicked.emit(self, character, is_special, action)
	if action != ButtonType.SHIFT and is_visible_in_tree():
		grab_focus()


func _on_focus_entered() -> void:
	focus_entered_info.emit(self, get_parent())
