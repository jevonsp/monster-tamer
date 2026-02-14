extends CanvasLayer
var processing: bool = false
@onready var monster_slot_0: Dictionary = {
	name = $MarginContainer/Content/GridContainer/Panel0/VBoxContainer/HBoxContainer0/MarginContainer0/NameLabel,
	level = $MarginContainer/Content/GridContainer/Panel0/VBoxContainer/HBoxContainer0/MarginContainer1/PlayerLevelLabel,
	portrait = $MarginContainer/Content/GridContainer/Panel0/VBoxContainer/HBoxContainer1/Portrait,
	hp = $MarginContainer/Content/GridContainer/Panel0/VBoxContainer/HBoxContainer1/VBoxContainer/HPBar,
	exp = $MarginContainer/Content/GridContainer/Panel0/VBoxContainer/HBoxContainer1/VBoxContainer/PlayerEXPBar,
}
@onready var monster_slot_1: Dictionary = {
	name = $MarginContainer/Content/GridContainer/Panel1/VBoxContainer/HBoxContainer0/MarginContainer0/NameLabel,
	level = $MarginContainer/Content/GridContainer/Panel1/VBoxContainer/HBoxContainer0/MarginContainer1/PlayerLevelLabel,
	portrait = $MarginContainer/Content/GridContainer/Panel1/VBoxContainer/HBoxContainer1/Portrait,
	hp = $MarginContainer/Content/GridContainer/Panel1/VBoxContainer/HBoxContainer1/VBoxContainer/HPBar,
	exp = $MarginContainer/Content/GridContainer/Panel1/VBoxContainer/HBoxContainer1/VBoxContainer/PlayerEXPBar,
}
@onready var monster_slot_2: Dictionary = {
	name = $MarginContainer/Content/GridContainer/Panel2/VBoxContainer/HBoxContainer0/MarginContainer0/NameLabel,
	level = $MarginContainer/Content/GridContainer/Panel2/VBoxContainer/HBoxContainer0/MarginContainer1/PlayerLevelLabel,
	portrait = $MarginContainer/Content/GridContainer/Panel2/VBoxContainer/HBoxContainer1/Portrait,
	hp = $MarginContainer/Content/GridContainer/Panel2/VBoxContainer/HBoxContainer1/VBoxContainer/HPBar,
	exp = $MarginContainer/Content/GridContainer/Panel2/VBoxContainer/HBoxContainer1/VBoxContainer/PlayerEXPBar,
}
@onready var monster_slot_3: Dictionary = {
	name = $MarginContainer/Content/GridContainer/Panel3/VBoxContainer/HBoxContainer0/MarginContainer0/NameLabel,
	level = $MarginContainer/Content/GridContainer/Panel3/VBoxContainer/HBoxContainer0/MarginContainer1/PlayerLevelLabel,
	portrait = $MarginContainer/Content/GridContainer/Panel3/VBoxContainer/HBoxContainer1/Portrait,
	hp = $MarginContainer/Content/GridContainer/Panel3/VBoxContainer/HBoxContainer1/VBoxContainer/HPBar,
	exp = $MarginContainer/Content/GridContainer/Panel3/VBoxContainer/HBoxContainer1/VBoxContainer/PlayerEXPBar,
}
@onready var monster_slot_4: Dictionary = {
	name = $MarginContainer/Content/GridContainer/Panel4/VBoxContainer/HBoxContainer0/MarginContainer0/NameLabel,
	level = $MarginContainer/Content/GridContainer/Panel4/VBoxContainer/HBoxContainer0/MarginContainer1/PlayerLevelLabel,
	portrait = $MarginContainer/Content/GridContainer/Panel4/VBoxContainer/HBoxContainer1/Portrait,
	hp = $MarginContainer/Content/GridContainer/Panel4/VBoxContainer/HBoxContainer1/VBoxContainer/HPBar,
	exp = $MarginContainer/Content/GridContainer/Panel4/VBoxContainer/HBoxContainer1/VBoxContainer/PlayerEXPBar,
}
@onready var monster_slot_5: Dictionary = {
	name = $MarginContainer/Content/GridContainer/Panel5/VBoxContainer/HBoxContainer0/MarginContainer0/NameLabel,
	level = $MarginContainer/Content/GridContainer/Panel5/VBoxContainer/HBoxContainer0/MarginContainer1/PlayerLevelLabel,
	portrait = $MarginContainer/Content/GridContainer/Panel5/VBoxContainer/HBoxContainer1/Portrait,
	hp = $MarginContainer/Content/GridContainer/Panel5/VBoxContainer/HBoxContainer1/VBoxContainer/HPBar,
	exp = $MarginContainer/Content/GridContainer/Panel5/VBoxContainer/HBoxContainer1/VBoxContainer/PlayerEXPBar,
}

func _ready() -> void:
	Global.send_player_party.connect(_on_party_change)
	Global.request_open_party.connect(_toggle_visible)
	if visible:
		_toggle_visible()

func _unhandled_input(event: InputEvent) -> void:
	if not processing:
		return
	if event.is_action_pressed("menu"):
		_toggle_visible()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("no"):
		_toggle_visible()
		Global.request_open_menu.emit()
		get_viewport().set_input_as_handled()

func _on_party_change(party: Array[Monster]) -> void:
	# Set all component's actor to new monster
	var party_index = 0
	for monster_slot in [monster_slot_0, monster_slot_1, monster_slot_2, monster_slot_3, monster_slot_4, monster_slot_5]:
		for key in monster_slot.keys():
			monster_slot[key].actor = party[party_index]
			print_debug("Assigned %s actor on %s" % [party[party_index].name, monster_slot[key]])
		party_index += 1
		if party_index >= party.size():
			print_debug("Party finished updated")
			return
	# Update information
	
	
func _toggle_visible() -> void:
	visible = not visible
	processing = not processing
	if visible:
		_focus_default()
		
		
func _focus_default() -> void:
	pass
