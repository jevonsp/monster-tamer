extends Button

@onready var name_label: Label = $VBoxContainer/HBoxContainer0/MarginContainer0/NameLabel
@onready var player_level_label: Label = $VBoxContainer/HBoxContainer0/MarginContainer1/PlayerLevelLabel
@onready var portrait: TextureRect = $VBoxContainer/HBoxContainer1/Portrait
@onready var hp_bar: ProgressBar = $VBoxContainer/HBoxContainer1/VBoxContainer/HPBar
@onready var player_exp_bar: ProgressBar = $VBoxContainer/HBoxContainer1/VBoxContainer/PlayerEXPBar

func update_actor(actor):
	for node in [
		name_label,
		player_level_label,
		portrait,
		hp_bar,
		player_exp_bar,
	]:
		node.actor = actor
		node.update()
	if actor == null:
		focus_mode = Control.FOCUS_NONE
