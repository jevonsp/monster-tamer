extends Control
var processing: bool = false
var party: Array[Monster]
var index: int = -1
var in_battle: bool = false
#region Onready Vars
@onready var gender_label: Label = $Content/Main/HBoxContainer0/GenderLabel
@onready var name_label: Label = $Content/Main/HBoxContainer0/NameLabel
@onready var level_label: Label = $Content/Main/HBoxContainer0/PlayerLevelLabel
@onready var hp_bar: ProgressBar = $Content/Main/HBoxContainer1/VBoxContainer/HPBar
@onready var exp_bar: ProgressBar = $Content/Main/HBoxContainer1/VBoxContainer/PlayerEXPBar
@onready var portrait: TextureRect = $Content/Main/HBoxContainer2/Portrait
@onready var description_label: Label = $Content/Main/HBoxContainer2/HBoxContainer/Panel0/MarginContainer/DescriptionLabel
@onready var stat_label_0: Label = $Content/Main/HBoxContainer2/HBoxContainer/Panel1/MarginContainer/Stats/StatLabel0
@onready var stat_label_1: Label = $Content/Main/HBoxContainer2/HBoxContainer/Panel1/MarginContainer/Stats/StatLabel1
@onready var stat_label_2: Label = $Content/Main/HBoxContainer2/HBoxContainer/Panel1/MarginContainer/Stats/StatLabel2
@onready var stat_label_3: Label = $Content/Main/HBoxContainer2/HBoxContainer/Panel1/MarginContainer/Stats/StatLabel3
@onready var stat_label_4: Label = $Content/Main/HBoxContainer2/HBoxContainer/Panel1/MarginContainer/Stats/StatLabel4
@onready var stat_label_5: Label = $Content/Main/HBoxContainer2/HBoxContainer/Panel1/MarginContainer/Stats/StatLabel5
@onready var summary_move_panel_0: Panel = $Content/Main/Moves/SummaryMovePanel0
@onready var summary_move_panel_1: Panel = $Content/Main/Moves/SummaryMovePanel1
@onready var summary_move_panel_2: Panel = $Content/Main/Moves/SummaryMovePanel2
@onready var summary_move_panel_3: Panel = $Content/Main/Moves/SummaryMovePanel3
#endregion


func _ready() -> void:
	if visible:
		_toggle_visible()
	_clear_monster()
	_connect_signals()


func _connect_signals() -> void:
	Global.send_player_party.connect(_set_player_party)
	Global.on_party_closed.connect(_clear_player_party)
	Global.request_open_summary.connect(_toggle_visible)
	Global.send_summary_index.connect(_set_party_index)
	Global.battle_started.connect(_on_battle_started)
	Global.battle_ended.connect(_on_battle_ended)


func _unhandled_input(event: InputEvent) -> void:
	if not processing:
		return
	if event.is_action_pressed("menu"):
		_toggle_visible()
		Global.on_summary_closed.emit()
		if not in_battle:
			Global.toggle_player.emit()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("no"):
		_toggle_visible()
		Global.on_summary_closed.emit()
		if not in_battle:
			Global.request_open_party.emit()
		get_viewport().set_input_as_handled()


func _clear_monster() -> void:
	var labels = [
		gender_label,
		name_label,
		level_label,
		description_label,
		stat_label_0,
		stat_label_1,
		stat_label_2,
		stat_label_3,
		stat_label_4,
		stat_label_5,
	]
	for label in labels:
		label.text = ""
	
	var move_panels = [
		summary_move_panel_0,
		summary_move_panel_1,
		summary_move_panel_2,
		summary_move_panel_3,
	]
	for panel in move_panels:
		for label in [
			panel.bp_label,
			panel.name_label,
			panel.pp_label,
			panel.description_label,
		]:
			label.text = ""
	portrait.texture = null
	for bar in [hp_bar, exp_bar]:
		bar.max_value = 100
		bar.value = 0


func _display_monster(monster: Monster) -> void:
	print("Displaying %s" % monster)
	print("Monster name: ", monster.name)
	print("Monster level: ", monster.level)
	print("Monster max_hitpoints: ", monster.max_hitpoints)
	print("Monster current_hitpoints: ", monster.current_hitpoints)
	print("Monster monster_data: ", monster.monster_data)
	gender_label.text = "TBD"
	name_label.text = monster.name
	level_label.text = "Lvl. %s" % [monster.level]
	
	hp_bar.max_value = monster.max_hitpoints
	hp_bar.value = monster.current_hitpoints
	hp_bar.actor = monster
	
	var min_exp: int = Monster.EXPERIENCE_PER_LEVEL * (monster.level - 1)
	var max_exp: int = Monster.EXPERIENCE_PER_LEVEL * monster.level
	
	exp_bar.max_value = max_exp
	exp_bar.min_value = min_exp
	exp_bar.value = monster.experience
	exp_bar.actor = monster
	
	portrait.texture = monster.monster_data.texture
	description_label.text = "TBD"
	
	stat_label_0.text = "TBD: "
	stat_label_1.text = "TBD: "
	stat_label_2.text = "TBD: "
	stat_label_3.text = "TBD: "
	stat_label_4.text = "TBD: "
	stat_label_5.text = "TBD: "
	
	var move_panels = [
		summary_move_panel_0,
		summary_move_panel_1,
		summary_move_panel_2,
		summary_move_panel_3,
	]
	var panel_index = 0
	for move in monster.moves:
		if move == null:
			continue
		move_panels[panel_index].bp_label.text = "BP: %s" % [move.base_power]
		move_panels[panel_index].name_label.text = move.name
		move_panels[panel_index].pp_label.text = "PP: XX"
		move_panels[panel_index].description_label.text = move.description
		panel_index += 1


func _set_party_index(i: int) -> void:
	index = i


func _on_battle_started() -> void:
	in_battle = true
	
	
func _on_battle_ended() -> void:
	in_battle = false


func _toggle_visible() -> void:
	print("%s toggled visible" % self)
	print("Summary visibility: ", visible)
	print("Party size: ", party.size())
	print("Index: ", index)
	visible = not visible
	processing = not processing
	if index > -1:
		print("Monster at index: ", party[index])
		print("Is monster valid? ", is_instance_valid(party[index]))
		var monster = party[index]
		_display_monster(monster)


func _set_player_party(p: Array[Monster]) -> void:
	print("Set player party - size: ", p.size())
	for i in p.size():
		print("  [%d]: %s (valid: %s)" % [i, p[i], is_instance_valid(p[i])])
	party = p
	

func _clear_player_party() -> void:
	party = []
	index = -1
