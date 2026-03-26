extends Button

var move: Move = null

@onready var bp_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/BPLabel
@onready var name_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/NameLabel
@onready var pp_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/PPLabel
@onready var description_label: Label = $MarginContainer/VBoxContainer/DescriptionLabel


func setup() -> void:
	if move != null:
		bp_label.text = "BP: %s" % [move.base_power]
		name_label.text = move.name
		pp_label.text = "PP: XX"
		description_label.text = move.description


func clear() -> void:
	for label in [bp_label, name_label, pp_label, description_label]:
		label.text = ""
	move = null
