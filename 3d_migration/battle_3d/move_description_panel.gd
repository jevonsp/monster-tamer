extends Button

var actor: Monster = null

@onready var bp_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/BPLabel
@onready var name_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/NameLabel
@onready var pp_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/PPLabel


func set_actor(a: Monster, update: bool = true) -> void:
	if not a:
		actor = null
		return
	actor = a
	if update:
		display()


func display(move: Move = null) -> void:
	if not move:
		return

	var current_pp = actor.move_pp[move]
	var damage: int = 0

	pp_label.text = "PP: %s" % [current_pp]
	name_label.text = move.name

	if not move.action_list or move.action_list.actions.is_empty():
		return

	for action in move.action_list.actions:
		if action is DamageAction:
			damage = action.base_power
	var damage_symbol: String = "-" if damage == 0 else str(damage)

	bp_label.text = "BP: %s" % [damage_symbol]
