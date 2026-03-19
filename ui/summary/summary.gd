extends Control
const DEFAULT_STYLE: StyleBoxFlat = preload("res://ui/summary/new_style_box_flat_default.tres")
const RED_STYLE: StyleBoxFlat = preload("res://ui/summary/new_style_box_flat_red.tres")
var processing: bool = false
var is_move_focused: bool = false
var is_learning_move: bool = false
var move_learning: Move = null
var learning_monster: Monster = null
var is_moving_move: bool = false
var party: Array[Monster] = []
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
	Global.battle_started.connect(_on_battle_started)
	Global.battle_ended.connect(_on_battle_ended)
	Global.request_summary_learn_move.connect(_on_request_summary_learn_move)
	Global.request_summary_move_learning.connect(_resolve_move_learning)


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
	if event.is_action_pressed("no"):
		handle_cancel_learning()
	if event.is_action("yes"):
		ask_remove_move()


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


func _toggle_visible(monster: Monster = null) -> void:
	visible = not visible
	processing = not processing
	if monster != null:
		_display_monster(monster)
		var idx = party.find(monster)
		_set_party_index(idx)
	if not visible:
		for b: Button in move_panels:
			b.clear()
			is_move_focused = false
			is_learning_move = false
			is_moving_move = false
			move_learning = null
			learning_monster = null


func _set_player_party(p: Array[Monster]) -> void:
	# WARNING This BORROWS the party from the player
	party = p
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
	if last_focused_move_button:
		last_focused_move_button.release_focus()
		last_focused_move_button = null
	moving_index_one = -1
	is_move_focused = false


func _start_moving_move() -> void:
	var idx = move_panels.find(last_focused_move_button)
	if idx != -1:
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


func _on_request_summary_learn_move(move: Move) -> void:
	is_learning_move = true
	move_learning = move


func _resolve_move_learning(monster: Monster, move: Move) -> void:
	learning_monster = monster
	move_learning = move

	var learn_index := monster.get_learn_index()
	if learn_index >= 0:
		print_debug("EXP: %s learning move in empty slot index=%s" % [monster.name, learn_index])
		monster.learn_move(move, learn_index)
		await _announce_move_learned(monster, move)
		Global.move_learning_finished.emit()
		return

	print_debug("EXP: %s has 4 moves; entering summary move learning" % [monster.name])
	var decided := false
	while not decided:
		Global.send_text_box.emit(
			monster,
			["%s is trying to learn %s, but already knows four moves. Delete one?" % [monster.name, move.name]],
			false,
			true,
			false
		)
		var answer = await Global.answer_given
		if not answer:
			decided = await handle_cancel_learning()
			continue
		decided = true

	is_learning_move = true
	Global.request_summary_learn_move.emit(move)
	if not visible:
		_toggle_visible(monster)
	else:
		_display_monster(monster)
		var idx = party.find(monster)
		if idx != -1:
			_set_party_index(idx)
	processing = true
	_focus_default_move()

func ask_remove_move() -> void:
	if last_focused_move_button == null or move_learning == null or learning_monster == null:
		return
	var move_removing = last_focused_move_button.move
	if move_removing == null:
		return
	var text_array: Array[String] = ["Are you sure you want to remove %s for %s?" % \
			[move_removing.name, move_learning.name]]
	Global.send_text_box.emit(null, text_array, false, true, false)
	var answer = await Global.answer_given
	if answer:
		var replacing_index := move_panels.find(last_focused_move_button)
		if replacing_index == -1:
			return
		learning_monster.learn_move(move_learning, replacing_index)
		_display_monster(learning_monster)
		_unfocus_moves()
		is_learning_move = false
		await _announce_move_learned(learning_monster, move_learning)
		_toggle_visible()
		Global.move_learning_finished.emit()

func handle_cancel_learning() -> bool:
	if learning_monster == null or move_learning == null:
		return false
	var text_array: Array[String] = ["Are you sure you want %s to stop learning %s" % \
			[learning_monster.name, move_learning.name]]
	Global.send_text_box.emit(null, text_array, false, true, false)
	var answer = await Global.answer_given
	if answer:
		text_array = ["%s did not learn %s" % [learning_monster.name, move_learning.name]]
		Global.send_text_box.emit(null, text_array, false, false, false)
		await Global.text_box_complete
		if visible:
			_toggle_visible()
		Global.move_learning_finished.emit()
		return true
	return false


func _announce_move_learned(monster: Monster, move: Move) -> void:
	Global.send_text_box.emit(monster, ["%s learned %s." % [monster.name, move.name]], false, false, false)
	await Global.text_box_complete
	print_debug("EXP: %s learn_move text complete" % [monster.name])
