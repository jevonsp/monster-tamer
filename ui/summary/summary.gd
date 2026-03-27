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
@onready var move_learning_controller: Node = $MoveLearningController
@onready var update_handler: Node = $UpdateHandler
@onready var visibility_focus_handler: Node = $"Visibility&FocusHandler"
@onready var input_handler: Node = $InputHandler
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
	update_handler.clear_monster()
	_connect_signals()
	_bind_buttons()
	if visible:
		processing = true


func show_monster(monster: Monster) -> void:
	update_handler.display_monster(monster)
	var idx := party.find(monster)
	if idx != -1:
		_set_party_index(idx)


func cycle_monster(direction: int) -> void:
	if party.is_empty():
		return
	index = posmod(index + direction, party.size())
	update_handler.display_monster(party[index])


func start_moving_move() -> void:
	var idx = move_panels.find(last_focused_move_button)
	if idx != -1:
		moving_index_one = idx
		is_moving_move = true
	visibility_focus_handler.highlight_move_swap()


func finish_moving_move() -> void:
	var idx = move_panels.find(last_focused_move_button)
	if idx != -1:
		var moving_index_two = idx
		Global.request_switch_moves.emit(party[index], moving_index_one, moving_index_two)
	moving_index_one = -1
	is_moving_move = false
	visibility_focus_handler.clear_move_swap_highlight()


func ask_remove_move() -> void:
	await move_learning_controller.ask_remove_move(self)


func handle_cancel_learning() -> bool:
	return await move_learning_controller.handle_cancel_learning(self)


func clean_up_learning_move() -> void:
	move_learning_controller.clean_up_learning_move(self)
#endregion


func _connect_signals() -> void:
	Global.send_player_party.connect(_set_player_party)
	Global.on_menu_closed.connect(_clear_player_party)
	Global.request_open_summary.connect(visibility_focus_handler.toggle_visible)
	Global.battle_started.connect(_on_battle_started)
	Global.battle_ended.connect(_on_battle_ended)
	Global.request_summary_learn_move.connect(_on_request_summary_learn_move)
	Global.request_summary_move_learning.connect(_resolve_move_learning)


func _bind_buttons() -> void:
	for b: Button in move_panels:
		b.focus_entered.connect(visibility_focus_handler.set_move_focus.bind(b))


func _set_party_index(i: int) -> void:
	index = i


func _on_battle_started() -> void:
	in_battle = true


func _on_battle_ended() -> void:
	in_battle = false


func _set_player_party(p: Array[Monster]) -> void:
	# WARNING This BORROWS the party from the player
	party = p
	if index >= 0 and index < party.size():
		update_handler.display_monster(party[index])
	else:
		update_handler.clear_monster()


func _clear_player_party() -> void:
	party = []
	index = -1


func _on_request_summary_learn_move(move: Move) -> void:
	is_learning_move = true
	move_learning = move


func _resolve_move_learning(monster: Monster, move: Move) -> void:
	await move_learning_controller.resolve_move_learning(self, monster, move)


func _set_move_learning_processing(value: bool, reason: String) -> void:
	move_learning_controller.set_move_learning_processing(self, value, reason)
