extends CanvasLayer

enum VisibilityState { OPTIONS, MOVES }

var vis_state: VisibilityState = VisibilityState.OPTIONS
var processing: bool = false

var player_actor: Monster
var enemy_actor: Monster
var player_party: Array[Monster] = []
var enemy_party: Array[Monster] = []

var turn_queue: Array = []

var _last_focused_option: int = 1
var _last_focused_move: int = 1

#region NODE REFERENCES
@onready var option_buttons_grid: GridContainer = $Content/OptionButtons
@onready var move_buttons_grid: GridContainer = $Content/MoveButtons
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var player_level_label: Label = $Content/PlayerLevelLabel
@onready var player_name_label: Label = $Content/PlayerNameLabel
@onready var player_texture_rect: TextureRect = $Content/PlayerTextureRect
@onready var player_hp_bar: ProgressBar = $Content/PlayerHPBar
@onready var player_exp_bar: ProgressBar = $Content/PlayerEXPBar

@onready var enemy_level_label: Label = $Content/EnemyLevelLabel
@onready var enemy_name_label: Label = $Content/EnemyNameLabel
@onready var enemy_texture_rect: TextureRect = $Content/EnemyTextureRect
@onready var enemy_hp_bar: ProgressBar = $Content/EnemyHPBar

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


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("no"):
		return
		
	match vis_state:
		VisibilityState.OPTIONS:
			option_buttons_grid.get_children()[2].grab_focus()
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
	
	var monster = monster_data.set_up(level)
	_set_wild_party([monster])
	set_enemy_actor()
	
	set_player_actor()
	
	_toggle_player()
	_display_current_monsters()
	_toggle_visible()


func end_battle() -> void:
	_clear_all()
	_toggle_visible()
	_toggle_player()


func _set_player_party(party: Array[Monster]) -> void:
	player_party = party


func _set_wild_party(party: Array[Monster]) -> void:
	enemy_party = party
	

func set_player_actor(monster: Monster = null) -> void: 
	if monster == null:
		player_actor = player_party[0]
	else:
		player_actor = monster
	player_actor.was_in_battle = true


func set_enemy_actor(monster: Monster = null) -> void: 
	if monster == null:
		enemy_actor = enemy_party[0]
	else:
		enemy_actor = monster

func _clear_actors() -> void:
	player_actor = null
	enemy_actor = null


func _clear_all() -> void:
	player_actor = null
	enemy_actor = null
	player_party = []
	enemy_party = []
	turn_queue.clear()
	vis_state = VisibilityState.OPTIONS
	processing = false
#endregion

#region # TURN EXECUTION
func _execute_player_turn(move: Move) -> void:
	if not _add_move_to_queue(move, player_actor):
		return
	
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
	
	if available_moves.is_empty():
		return
	
	var move = available_moves.pick_random()
	_add_move_to_queue(move, enemy_actor)


func _add_move_to_queue(move: Move, actor: Monster) -> bool:
	if move == null:
		return false
	
	var target = enemy_actor if actor == player_actor else player_actor
	if move.is_self_targeting:
		target = actor
	
	turn_queue.append({
		"action": move,
		"actor": actor,
		"target": target
	})
	return true


func _execute_turn_queue() -> void:
	_sort_turn_queue()
	
	for entry in turn_queue:
		var actor = entry.actor
		var target: Monster = entry.target
		var exp_completed = [false]
		var on_exp_complete = func(): exp_completed[0] = true
		Global.experience_animation_complete.connect(on_exp_complete, CONNECT_ONE_SHOT)
		
		await entry.action.execute(actor, target)
		if target and target.is_fainted and target == enemy_actor:
			if not exp_completed[0]:
				await Global.experience_animation_complete
				print("got signal")
		if _check_win():
			_win()
		if _check_lose():
			_lose()
			
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
			return false
	return true
	
	
func _check_lose() -> bool:
	for monster in player_party:
		if not monster.is_fainted:
			return false 
	return true
	
	
func _win() -> void:
	print("would win here")


func _lose() -> void:
	print("would lose here")
#endregion

#region # UI UPDATES
func _display_current_monsters() -> void:
	_update_levels()
	_update_names()
	_update_textures()
	_update_hitpoints()
	_update_exp()
	_update_moves()


func _update_levels() -> void:
	player_level_label.text = "Lvl. %s" % player_actor.level
	enemy_level_label.text = "Lvl. %s" % enemy_actor.level


func _update_names() -> void:
	player_name_label.text = player_actor.name
	enemy_name_label.text = enemy_actor.name


func _update_textures() -> void:
	player_texture_rect.texture = player_actor.monster_data.texture
	player_texture_rect.player_actor = player_actor # BIND
	enemy_texture_rect.texture = enemy_actor.monster_data.texture
	enemy_texture_rect.enemy_actor = enemy_actor # BIND


func _update_hitpoints() -> void:
	player_hp_bar.max_value = player_actor.max_hitpoints
	player_hp_bar.value = player_actor.current_hitpoints
	player_hp_bar.actor = player_actor # BIND
	
	enemy_hp_bar.max_value = enemy_actor.max_hitpoints
	enemy_hp_bar.value = enemy_actor.current_hitpoints
	enemy_hp_bar.actor = enemy_actor # BIND


func _update_exp() -> void:
	var max_exp = Monster.EXPERIENCE_PER_LEVEL * player_actor.level
	var min_exp = Monster.EXPERIENCE_PER_LEVEL * (player_actor.level - 1)
	
	player_exp_bar.max_value = max_exp
	player_exp_bar.min_value = min_exp
	player_exp_bar.value = player_actor.experience
	
	player_exp_bar.actor = player_actor


func _update_moves() -> void:
	for i in range(player_actor.moves.size()):
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

#region # UI FOCUS
func _change_vis_state(new_state: VisibilityState) -> void:
	vis_state = new_state
	
	match new_state:
		VisibilityState.OPTIONS:
			move_buttons_grid.visible = false
			option_buttons_grid.visible = true
			_focus_last_used_option()
		VisibilityState.MOVES:
			option_buttons_grid.visible = false
			move_buttons_grid.visible = true
			_focus_last_used_move()


func _focus_default() -> void:
	match vis_state:
		VisibilityState.OPTIONS:
			_focus_last_used_option()
		VisibilityState.MOVES:
			_focus_last_used_move()


func _focus_last_used_option() -> void:
	var children = option_buttons_grid.get_children()
	if _last_focused_option < children.size():
		children[_last_focused_option].grab_focus()


func _focus_last_used_move() -> void:
	var children = move_buttons_grid.get_children()
	if _last_focused_move < children.size():
		children[_last_focused_move].grab_focus()


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
	match button.name:
		"Party":
			_last_focused_option = 0
		"Fight":
			_last_focused_option = 1
			_change_vis_state(VisibilityState.MOVES)
		"Run":
			_last_focused_option = 2
			end_battle()
		"Item":
			_last_focused_option = 3


func _on_move_pressed(button: Button) -> void:
	var num = int(button.name.trim_prefix("Button"))
	_last_focused_move = num
	
	var move = player_actor.moves[num]
	_execute_player_turn(move)
#endregion
