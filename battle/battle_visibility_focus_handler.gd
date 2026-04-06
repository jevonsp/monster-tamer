extends Node

enum VisibilityState { OPTIONS, MOVES }

const BUTTON_PANEL_FOCUS_DEFAULT_STYLEBOX = preload("uid://ben02j7eumnqj")
const BUTTON_PANEL_FOCUS_MOVING_STYLEBOX = preload("uid://bg03qkarc7wjb")

var vis_state: VisibilityState = VisibilityState.OPTIONS
var last_selected_option: Button = null
var last_selected_move_button: Button = null
var is_moving_move: bool = false
var moving_index_one: int = -1

@onready var battle: Control = $".."
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var turn_executor: Node = $"../TurnExecutor"
@onready var move_info_helper_panel: Panel = $"../Content/MoveInfoHelperPanel"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("option"):
		if not is_moving_move:
			start_moving_move()
		else:
			finish_moving_move()


func connect_signals() -> void:
	Ui.on_inventory_closed.connect(focus_default)
	Ui.on_party_closed.connect(focus_default)
	Battle.request_display_monsters.connect(display_current_monsters)
	Party.send_player_party.connect(_on_player_party_updated)
	for child in battle.option_buttons_grid.get_children():
		if child is Button:
			child.focus_entered.connect(set_option_focus.bind(child))
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
			is_moving_move = false
			_set_move_panel_focus_style(BUTTON_PANEL_FOCUS_DEFAULT_STYLEBOX)
		VisibilityState.MOVES:
			move_info_helper_panel.toggle_visible(true)


func focus_default() -> void:
	if vis_state == VisibilityState.OPTIONS:
		_focus_default_options()
	else:
		_focus_default_moves()


func set_option_focus(button: Button) -> void:
	last_selected_option = button


func set_move_focus(button: Button) -> void:
	last_selected_move_button = button


func manage_focus() -> void:
	if battle.processing:
		focus_default()
	else:
		_drop_focus()


func on_option_pressed(button: Button) -> void:
	set_option_focus(button)

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
	set_move_focus(button)
	if not battle.processing or battle.battle_handler.executing_turn:
		return
	var num: int = _move_button_index(button)
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


func start_moving_move() -> void:
	var idx: int = _move_button_index(last_selected_move_button)
	if idx != -1:
		moving_index_one = idx
		is_moving_move = true
	highlight_move_swap()


func finish_moving_move() -> void:
	var idx: int = _move_button_index(last_selected_move_button)
	if idx != -1:
		var moving_index_two = idx
		Party.request_switch_moves.emit(battle.player_actor, moving_index_one, moving_index_two)
	moving_index_one = -1
	is_moving_move = false
	clear_move_swap_highlight()


func highlight_move_swap() -> void:
	_set_move_panel_focus_style(BUTTON_PANEL_FOCUS_MOVING_STYLEBOX)


func clear_move_swap_highlight() -> void:
	_set_move_panel_focus_style(BUTTON_PANEL_FOCUS_DEFAULT_STYLEBOX)


func _focus_default_options() -> void:
	var grid: Control = battle.option_buttons_grid
	if last_selected_option != null and is_instance_valid(last_selected_option):
		if last_selected_option.is_inside_tree() and last_selected_option.get_parent() == grid:
			last_selected_option.grab_focus()
			return

	var children: Array = grid.get_children()
	if children.is_empty():
		return

	var first_button := children[0] as Button
	if first_button:
		last_selected_option = first_button
		first_button.grab_focus()


func _focus_default_moves() -> void:
	var grid: Control = battle.move_buttons_grid
	var actor: Monster = battle.player_actor
	if not actor:
		return

	if last_selected_move_button != null and is_instance_valid(last_selected_move_button):
		if last_selected_move_button.is_inside_tree() and last_selected_move_button.get_parent() == grid:
			var idx: int = _move_button_index(last_selected_move_button)
			if idx >= 0 and idx < actor.moves.size() and actor.moves[idx] != null:
				last_selected_move_button.grab_focus()
				return

	for child in grid.get_children():
		if child is Button:
			var i: int = _move_button_index(child)
			if i >= 0 and i < actor.moves.size() and actor.moves[i] != null:
				last_selected_move_button = child
				child.grab_focus()
				return

	var children: Array = grid.get_children()
	if children.is_empty():
		return

	var first_button := children[0] as Button
	if first_button:
		last_selected_move_button = first_button
		first_button.grab_focus()


func _move_button_index(button: Button) -> int:
	return int(button.name.trim_prefix("Button"))


func _on_move_focus_entered(button: Button) -> void:
	set_move_focus(button)
	if not battle.player_actor:
		return

	var idx: int = _move_button_index(button)
	if idx < 0 or idx >= battle.player_actor.moves.size():
		return
	var move = battle.player_actor.moves[idx]
	var player_actor = battle.player_actor
	var enemy_actor = battle.enemy_actor

	Ui.send_move_helper_panel_info.emit(move, player_actor, enemy_actor)


func _drop_focus() -> void:
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()


func _set_move_panel_focus_style(style: StyleBoxTexture) -> void:
	for child in battle.move_buttons_grid.get_children():
		if child is Button:
			child.add_theme_stylebox_override("focus", style)


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


func _on_player_party_updated(_party: Array[Monster]) -> void:
	if not battle.player_actor:
		return
	_update_moves()


func _update_moves() -> void:
	for i in battle.player_actor.moves.size():
		if battle.player_actor.moves[i] != null:
			battle.move_labels[i].text = battle.player_actor.moves[i].name

	if not last_selected_move_button:
		return

	var idx: int = _move_button_index(last_selected_move_button)
	if idx < 0 or idx >= battle.player_actor.moves.size():
		return
	var move = battle.player_actor.moves[idx]
	var player_actor = battle.player_actor
	var enemy_actor = battle.enemy_actor

	Ui.send_move_helper_panel_info.emit(move, player_actor, enemy_actor)
