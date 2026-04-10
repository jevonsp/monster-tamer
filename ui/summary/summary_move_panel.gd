extends Button

var move: Move = null

@onready var bp_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/BPLabel
@onready var name_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/NameLabel
@onready var pp_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/PPLabel
@onready var description_label: Label = $MarginContainer/VBoxContainer/DescriptionLabel


func _ready() -> void:
	clear()


func setup() -> void:
	if move != null:
		bp_label.text = "BP: -"
		for effect in move.effects:
			if effect is DamageEffect:
				bp_label.text = "BP: %s" % effect.base_power
		name_label.text = move.name
		pp_label.text = "PP: %s" % move.base_pp
		description_label.text = move.description


func clear() -> void:
	for label in [bp_label, name_label, pp_label, description_label]:
		label.text = ""
	move = null


func _display_move(move_ref: Move, move_pp: Dictionary[Move, int]) -> void:
	if move_ref != null:
		bp_label.text = "BP: -"
		for effect in move_ref.effects:
			if effect is DamageEffect:
				bp_label.text = "BP: %s" % effect.base_power
		name_label.text = move_ref.name
		pp_label.text = "PP: %s" % move_pp[move_ref]
		description_label.text = move_ref.description
	else:
		clear()


func _toggle_visible(value: bool) -> void:
	visible = value
