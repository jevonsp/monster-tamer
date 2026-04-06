extends Node

enum VisibilityState { OPTIONS, MOVES }

var vis_state: VisibilityState = VisibilityState.OPTIONS
var _last_selected_by_state: Dictionary = {
	VisibilityState.OPTIONS: null,
	VisibilityState.MOVES: null,
}

@onready var battle: Control = $".."
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var turn_executor: Node = $"../TurnExecutor"
@onready var move_info_helper_panel: Panel = $"../Content/MoveInfoHelperPanel"


func connect_signals() -> void:
	Ui.on_inventory_closed.connect(focus_default)
	Ui.on_party_closed.connect(focus_default)
	Battle.request_display_monsters.connect(display_current_monsters)
	for child in battle.move_buttons_grid.get_children():
		if child is Button:
			child.focus_entered.connect(_on_move_focus_entered.bind(child))


func change_vis_state(new_state: VisibilityState) -> void:
	vis_state = new_state
	battle.option_buttons_grid.visible = new_state == VisibilityState.OPTIONS
	battle.move_buttons_grid.visible = new_state == VisibilityState.MOVES
	focus_default()
	match vis_state:
		VisibilityState.OPTIONS:
			move_info_helper_panel.toggle_visible(false)
		VisibilityState.MOVES:
			move_info_helper_panel.toggle_visible(true)


func focus_default() -> void:
	var grid: Control = (
		battle.option_buttons_grid
		if vis_state == VisibilityState.OPTIONS
		else battle.move_buttons_grid
	)
	var stored: Button = _last_selected_by_state[vis_state]

	if stored and stored.get_parent() == grid:
		stored.grab_focus()
		return

	var children: Array = grid.get_children()
	if children.is_empty():
		return

	var first_button := children[0] as Button
	if first_button:
		_last_selected_by_state[vis_state] = first_button
		first_button.grab_focus()


func manage_focus() -> void:
	if battle.processing:
		focus_default()
	else:
		_drop_focus()


func on_option_pressed(button: Button) -> void:
	_set_option_focus(button)

	match button.name:
		"Party":
			Ui.request_open_party.emit()
		"Fight":
			change_vis_state(VisibilityState.MOVES)
		"Run":
			battle.battle_handler.attempt_run()
		"Item":
			Ui.request_open_inventory.emit()


func on_move_pressed(button: Button) -> void:
	_set_move_focus(button)
	if not battle.processing or battle.battle_handler.executing_turn:
		return
	var num := int(button.name.trim_prefix("Button"))
	var move: Move = battle.player_actor.moves[num]
	if not move:
		return

	var player_actor: Monster = battle.player_actor
	if not player_actor.has_pp(move):
		var ta: Array[String] = \
		["Your %s cant use %s, they're out of PP!" % [player_actor.name, move.name]]
		Ui.send_text_box.emit(null, ta, true, false, false)
		await Ui.text_box_complete
		return

	player_actor.decrement_pp(move)
	battle.battle_handler.execute_player_turn(move)


func display_current_monsters() -> void:
	"""Main entry point for displaying new monsters"""
	_update_labels()
	_update_textures()
	_update_bars()
	_update_moves()


func clear_actor_references() -> void:
	battle.player_labels["level"].actor = null
	animation_player.player_actor = null
	animation_player.enemy_actor = null
	battle.player_display["hp_bar"].set_actor(null)
	battle.enemy_display["hp_bar"].set_actor(null)
	battle.player_display["exp_bar"].actor = null


func clear_textures() -> void:
	battle.player_display["texture"].texture = null
	battle.enemy_display["texture"].texture = null
	animation_player.play("RESET")


func _set_option_focus(button: Button) -> void:
	_last_selected_by_state[VisibilityState.OPTIONS] = button


func _set_move_focus(button: Button) -> void:
	_last_selected_by_state[VisibilityState.MOVES] = button


func _on_move_focus_entered(button: Button) -> void:
	if not battle.player_actor:
		return

	var move = battle.player_actor.moves[int(button.name)]
	var player_actor = battle.player_actor
	var enemy_actor = battle.enemy_actor

	Ui.send_move_helper_panel_info.emit(move, player_actor, enemy_actor)


func _drop_focus() -> void:
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()


func _update_labels() -> void:
	battle.player_labels["level"].text = "Lvl. %s" % battle.player_actor.level
	battle.player_labels["name"].text = battle.player_actor.name
	battle.player_labels["level"].actor = battle.player_actor
	battle.player_labels["level"].label_level = battle.player_actor.level

	battle.enemy_labels["level"].text = "Lvl. %s" % battle.enemy_actor.level
	battle.enemy_labels["name"].text = battle.enemy_actor.name


func _update_textures() -> void:
	battle.player_display["texture"].texture = battle.player_actor.monster_data.texture

	battle.enemy_display["texture"].texture = battle.enemy_actor.monster_data.texture

	animation_player.player_actor = battle.player_actor
	animation_player.enemy_actor = battle.enemy_actor


func _update_bars() -> void:
	"""Call only on new player_actor"""
	battle.player_display["hp_bar"].set_actor(battle.player_actor)
	battle.enemy_display["hp_bar"].set_actor(battle.enemy_actor)

	var min_exp: int = Monster.EXPERIENCE_PER_LEVEL * (battle.player_actor.level - 1)
	var max_exp: int = Monster.EXPERIENCE_PER_LEVEL * battle.player_actor.level

	battle.player_display["exp_bar"].min_value = min_exp
	battle.player_display["exp_bar"].max_value = max_exp
	battle.player_display["exp_bar"].value = battle.player_actor.experience
	battle.player_display["exp_bar"].actor = battle.player_actor


func _update_moves() -> void:
	for i in battle.player_actor.moves.size():
		if battle.player_actor.moves[i] != null:
			battle.move_labels[i].text = battle.player_actor.moves[i].name
