extends Node
enum VisibilityState { OPTIONS, MOVES }
const FOCUS_DEFAULTS = {
	OPTIONS = 1,
	MOVES = 1
}
var vis_state: VisibilityState = VisibilityState.OPTIONS
var _last_focused: Dictionary = {
	VisibilityState.OPTIONS: 1,
	VisibilityState.MOVES: 1
}
@onready var battle: Control = $".."

func _change_vis_state(new_state: VisibilityState) -> void:
	vis_state = new_state
	battle.option_buttons_grid.visible = new_state == VisibilityState.OPTIONS
	battle.move_buttons_grid.visible = new_state == VisibilityState.MOVES
	_focus_default()

func _focus_default() -> void:
	var grid = battle.option_buttons_grid if vis_state == VisibilityState.OPTIONS else battle.move_buttons_grid
	var index = _last_focused[vis_state]
	var children = grid.get_children()
	if index < children.size():
		children[index].grab_focus()

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
	var index_map := {"Party": 0, "Fight": 1, "Run": 2, "Item": 3}
	if button.name in index_map:
		_last_focused[VisibilityState.OPTIONS] = index_map[button.name]
		
	match button.name:
		"Fight":
			_change_vis_state(VisibilityState.MOVES)
		"Run":
			battle.end_battle()

func _on_move_pressed(button: Button) -> void:
	var num := int(button.name.trim_prefix("Button"))
	_last_focused[VisibilityState.MOVES] = num
	
	var move: Move = battle.player_actor.moves[num]
	battle.battle_handler._execute_player_turn(move)
