extends Control

var processing: bool = false
var player_actor: Monster:
	get:
		return session.player_actor
	set(value):
		session.set_player_actor(value)
var enemy_actor: Monster:
	get:
		return session.enemy_actor
	set(value):
		session.set_enemy_actor(value)
var player_party: Array[Monster]:
	get:
		return session.player_party
	set(value):
		session.set_player_party(value)
var is_wild_battle: bool:
	get:
		return session.is_wild_battle
	set(value):
		session.is_wild_battle = value
var enemy_trainer: Trainer:
	get:
		return session.enemy_trainer
	set(value):
		session.enemy_trainer = value
var enemy_party: Array[Monster]:
	get:
		return session.enemy_party
var _battle_intro_text_done: bool = false

@onready var interfaces: CanvasLayer = $".."
@onready var session = $BattleSession
@onready var option_buttons_grid: GridContainer = $Content/OptionButtons
@onready var run_button: Button = $Content/OptionButtons/Run
@onready var move_buttons_grid: GridContainer = $Content/MoveButtons
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player_labels: Dictionary = {
	level = $Content/PlayerPanel/VBoxContainer/PlayerLevelLabel,
	name = $Content/PlayerPanel/VBoxContainer/PlayerNameLabel,
}
@onready var player_display: Dictionary = {
	texture = $Content/PlayerTextureRect,
	hp_bar = $Content/PlayerHPBar,
	exp_bar = $Content/PlayerEXPBar,
}
@onready var enemy_labels: Dictionary = {
	level = $Content/EnemyPanel/VBoxContainer/EnemyLevelLabel,
	name = $Content/EnemyPanel/VBoxContainer/EnemyNameLabel,
}
@onready var enemy_display: Dictionary = {
	texture = $Content/EnemyTextureRect,
	hp_bar = $Content/EnemyHPBar,
}
@onready var move_labels: Array[Label] = [
	$Content/MoveButtons/Button0/Label,
	$Content/MoveButtons/Button1/Label,
	$Content/MoveButtons/Button2/Label,
	$Content/MoveButtons/Button3/Label,
]
@onready var battle_handler: Node = $BattleHandler
@onready var visibility_focus_handler: Node = $"Visibility&FocusHandler"
@onready var turn_executor: Node = $TurnExecutor


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
				visibility_focus_handler.change_vis_state(visibility_focus_handler.VisibilityState.OPTIONS)


func end_battle() -> void:
	_release_held_input_actions()
	var ended_trainer: Trainer = enemy_trainer
	_clear_all()
	_toggle_visible()
	_toggle_player()
	Battle.battle_ended.emit(ended_trainer)


func set_player_actor(monster: Monster) -> void:
	session.set_player_actor(monster)


func set_enemy_actor(monster: Monster) -> void:
	session.set_enemy_actor(monster)


func switch_actors(old: Monster, new: Monster) -> void:
	session.switch_actors(old, new)
	visibility_focus_handler.display_current_monsters()


func _toggle_visible() -> void:
	visible = !visible
	processing = visible
	if visible:
		visibility_focus_handler.focus_default()
		player_display["exp_bar"].active = true
	else:
		player_display["exp_bar"].active = false


func _toggle_player() -> void:
	Battle.toggle_in_battle.emit()


func _connect_signals() -> void:
	Party.send_player_party.connect(_set_player_party)
	Battle.wild_battle_requested.connect(_start_wild_battle)
	Battle.switch_battle_actors.connect(switch_actors)
	Battle.trainer_battle_requested.connect(_start_trainer_battle)
	visibility_focus_handler.connect_signals()


func _bind_buttons() -> void:
	for button in get_tree().get_nodes_in_group("option_buttons"):
		button.pressed.connect(visibility_focus_handler.on_option_pressed.bind(button))
	for button in get_tree().get_nodes_in_group("move_buttons"):
		button.pressed.connect(visibility_focus_handler.on_move_pressed.bind(button))


func _start_wild_battle(monster_data: MonsterData, level: int) -> void:
	processing = false
	Ui.switch_ui_context.emit(Global.AccessFrom.BATTLE)
	session.start_wild_battle(monster_data, level)
	await _switch_to_battle()


func _start_trainer_battle(trainer: Trainer) -> void:
	Ui.switch_ui_context.emit(Global.AccessFrom.BATTLE)
	session.start_trainer_battle(trainer)
	await _switch_to_battle()


func _switch_to_battle() -> void:
	if interfaces.has_method("end_field_suppress"):
		interfaces.end_field_suppress()
	visibility_focus_handler.display_current_monsters()
	_toggle_visible()
	_toggle_player()
	visibility_focus_handler.animation_player.play("both_switch_in")
	var ta: Array[String] = ["Get em, %s!" % player_actor.name]
	_battle_intro_text_done = false
	if not Ui.text_box_complete.is_connected(_on_battle_intro_text_line_done):
		Ui.text_box_complete.connect(_on_battle_intro_text_line_done, CONNECT_ONE_SHOT)
	Ui.send_text_box.emit(null, ta, true, false, false)
	await visibility_focus_handler.animation_player.animation_finished
	if not _battle_intro_text_done:
		await Ui.text_box_complete
	processing = true
	visibility_focus_handler.call_deferred("manage_focus")


func _on_battle_intro_text_line_done() -> void:
	_battle_intro_text_done = true


func _set_player_party(party: Array[Monster]) -> void:
	session.set_player_party(party)


func _release_held_input_actions() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	player.clear_inputs()


func _clear_all() -> void:
	session.clear_all_battle_state()
	visibility_focus_handler.clear_actor_references()
	visibility_focus_handler.clear_textures()
	battle_handler.turn_queue.clear()
	battle_handler.executing_turn = false
	turn_executor.run_count = 0
	processing = false
