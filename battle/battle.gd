extends CanvasLayer
enum VisibilityState { OPTIONS, MOVES }
const FOCUS_DEFAULTS = {
	OPTIONS = 1,
	MOVES = 1
}
var vis_state: VisibilityState = VisibilityState.OPTIONS
var processing: bool = false
var player_actor: Monster
var enemy_actor: Monster
var player_party: Array[Monster] = []
var enemy_party: Array[Monster] = []
var turn_queue: Array[Dictionary] = []
var _last_focused: Dictionary = {
	VisibilityState.OPTIONS: 1,
	VisibilityState.MOVES: 1
}
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

#region LIFECYCLE
func _ready() -> void:
	_connect_signals()
	_bind_buttons()
	if visible:
		_toggle_visible()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("no"):
		match vis_state:
			VisibilityState.OPTIONS:
				option_buttons_grid.get_child(2).grab_focus()
			VisibilityState.MOVES:
				_change_vis_state(VisibilityState.OPTIONS)

func _connect_signals() -> void:
	Global.send_player_party.connect(_set_player_party)
	Global.wild_battle_requested.connect(_start_wild_battle)

func _bind_buttons() -> void:
	for button in get_tree().get_nodes_in_group("option_buttons"):
		button.pressed.connect(_on_option_pressed.bind(button))
	for button in get_tree().get_nodes_in_group("move_buttons"):
		button.pressed.connect(_on_move_pressed.bind(button))
#endregion

#region BATTLE FLOW
func _start_wild_battle(monster_data: MonsterData, level: int) -> void:
	_clear_actors()
	
	var monster: Monster = monster_data.set_up(level)
	enemy_party = [monster]
	enemy_actor = enemy_party[0]
	
	player_actor = player_party[0]
	player_actor.was_in_battle = true
	
	_display_current_monsters()
	_toggle_player()
	_toggle_visible()

func end_battle() -> void:
	_clear_all()
	_toggle_visible()
	_toggle_player()
	Global.battle_ended.emit()

func _set_player_party(party: Array[Monster]) -> void:
	player_party = party

func _clear_actors() -> void:
	player_actor = null
	enemy_actor = null

func _clear_all() -> void:
	_clear_actors()
	player_party = []
	enemy_party = []
	_clear_actor_references()
	_clear_textures()
	turn_queue.clear()
	vis_state = VisibilityState.OPTIONS
	processing = false
#endregion

#region TURN EXECUTION
func _execute_player_turn(move: Move) -> void:
	if _add_move_to_queue(move, player_actor):
		processing = false
		_manage_focus()
		_get_enemy_action()
		await _execute_turn_queue()
		processing = true

func _get_enemy_action() -> void:
	var available_moves: Array[Move] = []
	for move in enemy_actor.moves:
		if move != null:
			available_moves.append(move)
	
	if not available_moves.is_empty():
		_add_move_to_queue(available_moves.pick_random(), enemy_actor)

func _add_move_to_queue(move: Move, actor: Monster) -> bool:
	if move == null:
		return false
	
	var target: Monster = _get_target(actor, move)
	turn_queue.append({
		"action": move,
		"actor": actor,
		"target": target
	})
	return true

func _get_target(actor: Monster, move: Move) -> Monster:
	if move.is_self_targeting:
		return actor
	return enemy_actor if actor == player_actor else player_actor

func _execute_turn_queue() -> void:
	_sort_turn_queue()
	
	for entry in turn_queue:
		var actor: Monster = entry.actor
		var target: Monster = entry.target
		print_debug("Actor: ", actor.name)
		print_debug("Target: ", target.name)
		var exp_completed = [false]
		var on_exp_complete = func(): exp_completed[0] = true
		Global.experience_animation_complete.connect(on_exp_complete, CONNECT_ONE_SHOT)
		
		await entry.action.execute(actor, target)
		if target and target.is_fainted and target == enemy_actor:
			if not exp_completed[0]:
				await Global.experience_animation_complete
		
		if _check_win():
			_win()
			return
		if _check_lose():
			_lose()
			return
			
	turn_queue.clear()
	processing = true
	_manage_focus()

func _sort_turn_queue() -> void:
	turn_queue.sort_custom(func(a, b): 
		if a.action.priority != b.action.priority:
			return a.action.priority > b.action.priority
		return a.actor.speed > b.actor.speed
	)

func _check_win() -> bool:
	for monster in enemy_party:
		if not monster.is_fainted:
			print_debug("enemy monster: %s is alive" % [monster.name])
			return false
	return true

func _check_lose() -> bool:
	for monster in player_party:
		if not monster.is_fainted:
			print_debug("player monster: %s is alive" % [monster.name])
			return false
	return true

func _win() -> void:
	var text: Array[String] = ["You won!"]
	Global.send_battle_text_box.emit(text, false)
	await Global.battle_text_box_complete
	end_battle()

func _lose() -> void:
	var text: Array[String] = ["You lost!"]
	Global.send_battle_text_box.emit(text, false)
	await Global.battle_text_box_complete
	end_battle()
	Global.send_respawn_player.emit()
#endregion

#region UI UPDATES
func _display_current_monsters() -> void:
	"""Main entry point for displaying new monsters"""
	_update_labels()
	_update_textures()
	_update_bars()
	_update_moves()

func _update_labels() -> void:
	player_labels["level"].text = "Lvl. %s" % player_actor.level
	player_labels["name"].text = player_actor.name
	player_labels["level"].actor = player_actor
	player_labels["level"].label_level = player_actor.level
	
	enemy_labels["level"].text = "Lvl. %s" % enemy_actor.level
	enemy_labels["name"].text = enemy_actor.name

func _update_textures() -> void:
	player_display["texture"].texture = player_actor.monster_data.texture
	player_display["texture"].player_actor = player_actor
	
	enemy_display["texture"].texture = enemy_actor.monster_data.texture
	enemy_display["texture"].enemy_actor = enemy_actor

func _update_bars() -> void:
	"""Call only on new player_actor"""
	player_display["hp_bar"].max_value = player_actor.max_hitpoints
	player_display["hp_bar"].value = player_actor.current_hitpoints
	player_display["hp_bar"].actor = player_actor
	
	enemy_display["hp_bar"].max_value = enemy_actor.max_hitpoints
	enemy_display["hp_bar"].value = enemy_actor.current_hitpoints
	enemy_display["hp_bar"].actor = enemy_actor
	
	var min_exp: int = Monster.EXPERIENCE_PER_LEVEL * (player_actor.level - 1)
	var max_exp: int = Monster.EXPERIENCE_PER_LEVEL * player_actor.level
	
	player_display["exp_bar"].max_value = max_exp
	player_display["exp_bar"].min_value = min_exp
	player_display["exp_bar"].value = player_actor.experience
	player_display["exp_bar"].actor = player_actor

func _clear_actor_references() -> void:
	player_labels["level"].actor = null
	player_display["texture"].player_actor = null
	enemy_display["texture"].enemy_actor = null
	player_display["hp_bar"].actor = null
	enemy_display["hp_bar"].actor = null
	player_display["exp_bar"].actor = null

func _clear_textures() -> void:
	player_display["texture"].texture = null
	enemy_display["texture"].texture = null

func _update_moves() -> void:
	for i in player_actor.moves.size():
		if player_actor.moves[i] != null:
			move_labels[i].text = player_actor.moves[i].name

func _toggle_player() -> void:
	Global.toggle_player.emit()

func _toggle_visible() -> void:
	visible = !visible
	processing = !processing
	if visible:
		_focus_default()
#endregion

#region UI FOCUS
func _change_vis_state(new_state: VisibilityState) -> void:
	vis_state = new_state
	option_buttons_grid.visible = new_state == VisibilityState.OPTIONS
	move_buttons_grid.visible = new_state == VisibilityState.MOVES
	_focus_default()

func _focus_default() -> void:
	var grid = option_buttons_grid if vis_state == VisibilityState.OPTIONS else move_buttons_grid
	var index = _last_focused[vis_state]
	var children = grid.get_children()
	if index < children.size():
		children[index].grab_focus()

func _drop_focus() -> void:
	var focused = get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()

func _manage_focus() -> void:
	if processing:
		_focus_default()
	else:
		_drop_focus()
#endregion

#region INPUT HANDLERS
func _on_option_pressed(button: Button) -> void:
	var index_map := {"Party": 0, "Fight": 1, "Run": 2, "Item": 3}
	if button.name in index_map:
		_last_focused[VisibilityState.OPTIONS] = index_map[button.name]
		
	match button.name:
		"Fight":
			_change_vis_state(VisibilityState.MOVES)
		"Run":
			end_battle()

func _on_move_pressed(button: Button) -> void:
	var num := int(button.name.trim_prefix("Button"))
	_last_focused[VisibilityState.MOVES] = num
	
	var move: Move = player_actor.moves[num]
	_execute_player_turn(move)
#endregion
