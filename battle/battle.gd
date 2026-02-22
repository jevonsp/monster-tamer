extends Control
var processing: bool = false
var player_actor: Monster
var enemy_actor: Monster
var player_party: Array[Monster] = []
var enemy_party: Array[Monster] = []
#region NODE REFERENCES
@onready var option_buttons_grid: GridContainer = $Content/OptionButtons
@onready var move_buttons_grid: GridContainer = $Content/MoveButtons
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var player_labels: Dictionary = {
	level = $Content/PlayerLevelLabel,
	name = $Content/PlayerNameLabel
}
@onready var player_display: Dictionary = {
	texture = $Content/PlayerTextureRect,
	hp_bar = $Content/PlayerHPBar,
	exp_bar = $Content/PlayerEXPBar
}

@onready var enemy_labels: Dictionary = {
	level = $Content/EnemyLevelLabel,
	name = $Content/EnemyNameLabel
}
@onready var enemy_display: Dictionary = {
	texture = $Content/EnemyTextureRect,
	hp_bar = $Content/EnemyHPBar
}

@onready var move_labels: Array[Label] = [
	$Content/MoveButtons/Button0/Label,
	$Content/MoveButtons/Button1/Label,
	$Content/MoveButtons/Button2/Label,
	$Content/MoveButtons/Button3/Label
]
#endregion

@onready var ui_handler: Node = $UIHandler
@onready var battle_handler: Node = $BattleHandler
@onready var input_handler: Node = $InputHandler

#region LIFECYCLE
func _ready() -> void:
	_connect_signals()
	_bind_buttons()
	if visible:
		_toggle_visible()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("no"):
		match input_handler.vis_state:
			input_handler.VisibilityState.OPTIONS:
				option_buttons_grid.get_child(2).grab_focus()
			input_handler.VisibilityState.MOVES:
				input_handler._change_vis_state(input_handler.VisibilityState.OPTIONS)


func _toggle_visible() -> void:
	visible = !visible
	processing = !processing
	if visible:
		input_handler._focus_default()


func _toggle_player() -> void:
	Global.toggle_player.emit()


func _connect_signals() -> void:
	Global.send_player_party.connect(_set_player_party)
	Global.wild_battle_requested.connect(_start_wild_battle)


func _bind_buttons() -> void:
	for button in get_tree().get_nodes_in_group("option_buttons"):
		button.pressed.connect(input_handler._on_option_pressed.bind(button))
	for button in get_tree().get_nodes_in_group("move_buttons"):
		button.pressed.connect(input_handler._on_move_pressed.bind(button))
#endregion

#region BATTLE FLOW
func _start_wild_battle(monster_data: MonsterData, level: int) -> void:
	_clear_actors()
	
	var monster: Monster = monster_data.set_up(level)
	enemy_party = [monster]
	enemy_actor = enemy_party[0]
	
	player_actor = player_party[0]
	player_actor.was_in_battle = true
	
	ui_handler._display_current_monsters()
	_toggle_player()
	_toggle_visible()


func _start_trainer_battle(trainer_party: Array[Monster]) -> void:
	_clear_actors()
	
	enemy_party = trainer_party.duplicate()
	enemy_actor = enemy_party[0]
	

func end_battle() -> void:
	_clear_all()
	_toggle_visible()
	_toggle_player()
	Global.battle_ended.emit()


func _set_player_party(party: Array[Monster]) -> void:
	player_party = party


func _check_player_actor_fainted() -> bool:
	return player_actor.is_fainted


func _check_enemy_actor_fainted() -> bool:
	return enemy_actor.is_fainted


func _clear_actors() -> void:
	player_actor = null
	enemy_actor = null


func _clear_all() -> void:
	_clear_actors()
	player_party = []
	enemy_party = []
	ui_handler._clear_actor_references()
	ui_handler._clear_textures()
	battle_handler.turn_queue.clear()
	input_handler.vis_state = input_handler.VisibilityState.OPTIONS
	processing = false
#endregion
