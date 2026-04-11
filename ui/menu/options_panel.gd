extends Panel

@export var option_entries: Array[OptionEntry] = []

var current_index_number: int = 0
var number_of_pages: int = 0

@onready var option_button_0: Button = $MarginContainer/HBoxContainer/Buttons/OptionButton0
@onready var option_button_1: Button = $MarginContainer/HBoxContainer/Buttons/OptionButton1
@onready var option_button_2: Button = $MarginContainer/HBoxContainer/Buttons/OptionButton2
@onready var option_button_3: Button = $MarginContainer/HBoxContainer/Buttons/OptionButton3
@onready var label_0: Label = $MarginContainer/HBoxContainer/Settings/Label0
@onready var label_1: Label = $MarginContainer/HBoxContainer/Settings/Label1
@onready var label_2: Label = $MarginContainer/HBoxContainer/Settings/Label2
@onready var label_3: Label = $MarginContainer/HBoxContainer/Settings/Label3
@onready var button_label_pairs: Dictionary[int, Array] = {
	0: [option_button_0, label_0],
	1: [option_button_1, label_1],
	2: [option_button_2, label_2],
	3: [option_button_3, label_3],
}


func _ready() -> void:
	number_of_pages = ceil(option_entries.size() / 4.0)
	display_page(0)
	_bind_buttons()


func display_page(index: int) -> void:
	if index >= number_of_pages:
		return

	var count: int = 0
	for i in range(index, index + 4):
		var entry: OptionEntry = option_entries[index]
		display_entry(entry, count)
		if count >= option_entries.size() + 1:
			break


func display_entry(entry: OptionEntry, count: int) -> void:
	var button: Button = button_label_pairs[count][0]
	var label: Label = button_label_pairs[count][1]

	button.toggle_mode = true if entry.type == OptionEntry.Type.TOGGLE else false
	label.text = entry.entry_texts[entry.chosen_entry]


func get_entry(button: Button, index: int) -> OptionEntry:
	var button_index = button.name.to_int()
	var entry_number = button_index + (4 * index)

	if entry_number >= option_entries.size():
		return null

	return option_entries[entry_number]


func _bind_buttons() -> void:
	for button: Button in [
		option_button_0,
		option_button_1,
		option_button_2,
		option_button_3,
	]:
		button.pressed.connect(_on_button_pressed.bind(button))


func _on_button_pressed(button: Button) -> void:
	var entry = get_entry(button, current_index_number)
	entry.chosen_entry = (entry.chosen_entry + 1) % (entry.entries)

	display_page(current_index_number)
