extends Node
enum VisibilityState { OPTIONS, MOVES }
var vis_state: VisibilityState = VisibilityState.OPTIONS:
	set(value):
		vis_state = value
		print(VisibilityState.keys()[value])
var _last_selected_by_state: Dictionary = {
	VisibilityState.OPTIONS: null,
	VisibilityState.MOVES: null
}
@onready var battle: Control = $".."


func _connect_signals() -> void:
	Global.on_inventory_closed.connect(_focus_default)
	Global.on_party_closed.connect(_focus_default)


func _change_vis_state(new_state: VisibilityState) -> void:
	vis_state = new_state
	battle.option_buttons_grid.visible = new_state == VisibilityState.OPTIONS
	battle.move_buttons_grid.visible = new_state == VisibilityState.MOVES
	_focus_default()


func _set_option_focus(button: Button) -> void:
	_last_selected_by_state[VisibilityState.OPTIONS] = button


func _set_move_focus(button: Button) -> void:
	_last_selected_by_state[VisibilityState.MOVES] = button


func _focus_default() -> void:
	var grid = battle.option_buttons_grid if vis_state == VisibilityState.OPTIONS else battle.move_buttons_grid
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


func _drop_focus() -> void:
	var focused = get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()


func _manage_focus() -> void:
	if battle.processing:
		_focus_default()
	else:
		_drop_focus()
		
		
func _on_option_pressed(button: Button) -> void:
	_set_option_focus(button)
	
	match button.name:
		"Party":
			Global.request_open_party.emit()
		"Fight":
			_change_vis_state(VisibilityState.MOVES)
		"Run":
			battle.end_battle()
		"Item":
			Global.request_open_inventory.emit()


func _on_move_pressed(button: Button) -> void:
	_set_move_focus(button)
	var num := int(button.name.trim_prefix("Button"))
	var move: Move = battle.player_actor.moves[num]
	battle.battle_handler._execute_player_turn(move)
