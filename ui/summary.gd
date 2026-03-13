extends Control
var DEFAULT_STYLE: StyleBoxFlat = load("res://ui/new_style_box_flat_default.tres")
var RED_STYLE: StyleBoxFlat = load("res://ui/new_style_box_flat_red.tres")
var processing: bool = false
var is_move_focused: bool = false
var is_learning_move: bool = false
var is_moving_move: bool = false
var party: Array[Monster]
var index: int = -1
var in_battle: bool = false
var last_focused_move_button: Button = null
var moving_index_one: int = -1
@onready var interfaces: CanvasLayer = $".."
@onready var overworld_text_box: Control = $"../OverworldTextBox"
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
@onready var summary_move_panel_0: Button = $Content/Main/Moves/SummaryMovePanel0
@onready var summary_move_panel_1: Button = $Content/Main/Moves/SummaryMovePanel1
@onready var summary_move_panel_2: Button = $Content/Main/Moves/SummaryMovePanel2
@onready var summary_move_panel_3: Button = $Content/Main/Moves/SummaryMovePanel3
#endregion

@onready var labels: Array[Label] = [
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

@onready var move_panels: Array[Button] = [
	summary_move_panel_0,
	summary_move_panel_1,
	summary_move_panel_2,
	summary_move_panel_3,
]

func _ready() -> void:
	if visible:
		_toggle_visible()
	_clear_monster()
	_connect_signals()
	_bind_buttons()


func _connect_signals() -> void:
	Global.send_player_party.connect(_set_player_party)
	Global.on_menu_closed.connect(_clear_player_party)
	Global.request_open_summary.connect(_toggle_visible)
	Global.send_summary_index.connect(_set_party_index)
	Global.battle_started.connect(_on_battle_started)
	Global.battle_ended.connect(_on_battle_ended)


func _bind_buttons() -> void:
	for b: Button in move_panels:
		b.focus_entered.connect(_on_focus_entered.bind(b))


func _unhandled_input(event: InputEvent) -> void:
	if not processing:
		return

	if is_learning_move:
		_handle_learning_input(event)
	elif is_move_focused:
		_handle_move_focused_input(event)
	else:
		_handle_default_input(event)


func _handle_default_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		_toggle_visible()
		Global.on_summary_closed.emit()
		if not in_battle:
			Global.toggle_player.emit()
	elif event.is_action_pressed("no"):
		_toggle_visible()
		Global.on_summary_closed.emit()
		if not in_battle:
			Global.request_open_party.emit()
	elif event.is_action_pressed("right"):
		index = (index + 1) % party.size()
		_clear_monster()
		_display_monster(party[index])
	elif event.is_action_pressed("left"):
		index = (index - 1) % party.size()
		_clear_monster()
		_display_monster(party[index])
	elif event.is_action_pressed("yes"):
		_focus_default_move()
	else:
		return

	get_viewport().set_input_as_handled()


func _handle_move_focused_input(event: InputEvent) -> void:
	if event.is_action_pressed("yes"):
		if not is_moving_move:
			_start_moving_move()
		else:
			_finish_moving_move()
	elif event.is_action_pressed("no"):
		_unfocus_moves()
		
	get_viewport().set_input_as_handled()


func _handle_learning_input(event: InputEvent) -> void:
	if last_focused_move_button.move == null:
		pass


func _clear_monster() -> void:
	for label in labels:
		label.text = ""
	
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
	
	var panel_index = 0
	for move in monster.moves:
		if move == null:
			move_panels[panel_index].clear()
		move_panels[panel_index].move = move
		move_panels[panel_index].setup()
		panel_index += 1


func _set_party_index(i: int) -> void:
	index = i


func _on_battle_started() -> void:
	in_battle = true
	
	
func _on_battle_ended() -> void:
	in_battle = false


func _toggle_visible() -> void:
	visible = not visible
	processing = not processing
	if index > -1:
		var monster = party[index]
		_display_monster(monster)
	if not visible:
		for b: Button in move_panels:
			b.clear()


func _set_player_party(p: Array[Monster]) -> void:
	# WARNING This BORROWS the party from the player
	party = p
	print("got party: ", party)
	_display_monster(party[index])


func _clear_player_party() -> void:
	party = []
	index = -1


func _on_focus_entered(button: Button) -> void:
	last_focused_move_button = button 


func _focus_default_move() -> void:
	is_move_focused = true
	if last_focused_move_button:
		last_focused_move_button.grab_focus()
		return
	summary_move_panel_0.grab_focus()


func _unfocus_moves() -> void:
	last_focused_move_button.release_focus()
	moving_index_one = -1
	is_move_focused = false


func _start_moving_move() -> void:
	var idx = move_panels.find(last_focused_move_button)
	if idx != -1:
		print(idx)
		moving_index_one = idx
		is_moving_move = true
	for button in move_panels:
		button.add_theme_stylebox_override("focus", RED_STYLE)


func _finish_moving_move() -> void:
	var idx = move_panels.find(last_focused_move_button)
	if idx != -1:
		var moving_index_two = idx
		Global.request_switch_moves.emit(party[index], moving_index_one, moving_index_two)
	moving_index_one = -1
	is_moving_move = false
	for button in move_panels:
		button.add_theme_stylebox_override("focus", DEFAULT_STYLE)
