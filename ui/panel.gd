extends Button
var actor: Monster = null
@onready var name_label: Label = $VBoxContainer/HBoxContainer0/MarginContainer0/NameLabel
@onready var player_level_label: Label = $VBoxContainer/HBoxContainer0/MarginContainer1/PlayerLevelLabel
@onready var portrait: TextureRect = $VBoxContainer/HBoxContainer1/Portrait
@onready var hp_bar: ProgressBar = $VBoxContainer/HBoxContainer1/VBoxContainer/HPBar
@onready var player_exp_bar: ProgressBar = $VBoxContainer/HBoxContainer1/VBoxContainer/PlayerEXPBar

func update_actor(a: Monster) -> void:
	for node in [
		name_label,
		player_level_label,
		portrait,
		hp_bar,
		player_exp_bar,
	]:
		actor = a
		node.actor = a
		node.update()
	if actor == null:
		focus_mode = Control.FOCUS_NONE
