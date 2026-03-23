extends Control
var processing: bool = false
var player_actor: Monster
var enemy_actor: Monster
var player_party: Array[Monster] = []
var is_wild_battle: bool = true
var enemy_trainer: Trainer = null
var enemy_party: Array[Monster] = []
@onready var interfaces: CanvasLayer = $".."

#region NODE REFERENCES
@onready var option_buttons_grid: GridContainer = $Content/OptionButtons
@onready var run_button: Button = $Content/OptionButtons/Run
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

@onready var battle_handler: Node = $BattleHandler
@onready var visibility_focus_handler: Node = $"Visibility&FocusHandler"
@onready var turn_executor: Node = $TurnExecutor


#region LIFECYCLE
func _ready() -> void:
	_connect_signals()
	_bind_buttons()
	if visible:
		_toggle_visible()


func _unhandled_input(event: InputEvent) -> void:
	if battle_handler.executing_turn:
		return
	if event.is_action_pressed("no"):
		match visibility_focus_handler.vis_state:
			visibility_focus_handler.VisibilityState.OPTIONS:
				run_button.grab_focus()
			visibility_focus_handler.VisibilityState.MOVES:
				visibility_focus_handler._change_vis_state(visibility_focus_handler.VisibilityState.OPTIONS)


func _toggle_visible() -> void:
	visible = !visible
	processing = !processing
	if visible:
		visibility_focus_handler._focus_default()
		player_display["exp_bar"].active = true
	else:
		player_display["exp_bar"].active = false


func _toggle_player() -> void:
	Global.toggle_player.emit()
	Global.toggle_in_battle.emit()


func _connect_signals() -> void:
	Global.send_player_party.connect(_set_player_party)
	Global.wild_battle_requested.connect(_start_wild_battle)
	Global.switch_battle_actors.connect(switch_actors)
	Global.trainer_battle_requested.connect(_start_trainer_battle)
	visibility_focus_handler._connect_signals()


func _bind_buttons() -> void:
	for button in get_tree().get_nodes_in_group("option_buttons"):
		button.pressed.connect(visibility_focus_handler._on_option_pressed.bind(button))
	for button in get_tree().get_nodes_in_group("move_buttons"):
		button.pressed.connect(visibility_focus_handler._on_move_pressed.bind(button))
#endregion

#region BATTLE FLOW
func _start_wild_battle(monster_data: MonsterData, level: int) -> void:
	processing = false
	Global.switch_ui_context.emit(Global.AccessFrom.BATTLE)
	_clear_actors()
	
	var monster: Monster = monster_data.set_up(level)
	enemy_party = [monster]
	set_enemy_actor(enemy_party[0])
	set_player_actor(player_party[0])
	
	await _switch_to_battle()


func _start_trainer_battle(trainer: Trainer) -> void:
	Global.switch_ui_context.emit(Global.AccessFrom.BATTLE)
	_clear_actors()
	is_wild_battle = false
	
	enemy_trainer = trainer
	_set_enemy_party(trainer.party, trainer.party_levels)
	set_enemy_actor(enemy_party[0])
	set_player_actor(player_party[0])
	
	await _switch_to_battle()


func _switch_to_battle() -> void:
	visibility_focus_handler._display_current_monsters()
	_toggle_player()
	_toggle_visible()
	visibility_focus_handler.animation_player.play("both_switch_in")
	await visibility_focus_handler.animation_player.animation_finished
	processing = true


func end_battle() -> void:
	_clear_all()
	_toggle_visible()
	_toggle_player()
	Global.battle_ended.emit()


func set_player_actor(monster: Monster) -> void:
	player_actor = monster
	if player_actor:
		player_actor.was_active_in_battle = true


func set_enemy_actor(monster: Monster) -> void:
	enemy_actor = monster


func _set_player_party(party: Array[Monster]) -> void:
	player_party = party


func _set_enemy_party(party: Array[MonsterData], levels: Array[int]) -> void:
	for i in range(len(party)):
		var monster: Monster = party[i].set_up(levels[i])
		enemy_party.append(monster)


func switch_actors(old: Monster, new: Monster) -> void:
	if old == player_actor:
		player_actor = new
		if player_actor:
			player_actor.was_active_in_battle = true
	elif old == enemy_actor:
		enemy_actor = new
	visibility_focus_handler._display_current_monsters()


func _check_player_actor_fainted() -> bool:
	return player_actor.is_fainted


func _check_enemy_actor_fainted() -> bool:
	return enemy_actor.is_fainted


func _clear_actors() -> void:
	player_actor = null
	enemy_actor = null


func _clear_all() -> void:
	_clear_actors()
	is_wild_battle = true
	enemy_trainer = null
	player_party = []
	enemy_party = []
	visibility_focus_handler._clear_actor_references()
	visibility_focus_handler._clear_textures()
	battle_handler.turn_queue.clear()
	battle_handler.executing_turn = false
	turn_executor.run_count = 0
	processing = false
#endregion
