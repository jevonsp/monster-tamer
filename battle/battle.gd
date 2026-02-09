extends CanvasLayer
enum VisibilityState {OPTIONS, MOVES}	
var vis_state: VisibilityState = VisibilityState.OPTIONS

var processing: bool = false

var player_actor
var enemy_actor
var player_party: Array[Monster] = []
var enemy_party: Array[Monster] = []

var last_focused_option: int = 1:
	set(value):
		last_focused_option = value
		if value > 3 or value < 0:
			last_focused_option = 1
			printerr("Focus option set to invalid number. Resetting to 1.")
var last_focused_move: int = 1:
	set(value):
		last_focused_move = value
		if value > 3 or value < 0:
			last_focused_move = 1
			printerr("Focus option set to invalid number. Resetting to 1.")

@onready var option_buttons_grid: GridContainer = $Content/OptionButtons
@onready var move_buttons_grid: GridContainer = $Content/MoveButtons
@onready var move_label_0: Label = $Content/MoveButtons/Button0/Label
@onready var move_label_1: Label = $Content/MoveButtons/Button1/Label
@onready var move_label_2: Label = $Content/MoveButtons/Button2/Label
@onready var move_label_3: Label = $Content/MoveButtons/Button3/Label
@onready var player_level_label: Label = $Content/Player/LevelLabel
@onready var player_name_label: Label = $Content/Player/NameLabel
@onready var player_texture_rect: TextureRect = $Content/Player/TextureRect
@onready var player_hp_bar: ProgressBar = $Content/Player/HPBar
@onready var player_exp_bar: ProgressBar = $Content/Player/EXPBar
@onready var enemy_level_label: Label = $Content/Enemy/LevelLabel
@onready var enemy_name_label: Label = $Content/Enemy/NameLabel
@onready var enemy_texture_rect: TextureRect = $Content/Enemy/TextureRect
@onready var enemy_hp_bar: ProgressBar = $Content/Enemy/HPBar


func _ready() -> void:
	Global.send_player_party.connect(set_player_party)
	Global.wild_battle_requested.connect(create_wild_battle)
	bind_buttons()


func _input(event: InputEvent) -> void:
	if not processing:
		return
	match vis_state:
		VisibilityState.OPTIONS:
			if event.is_action_pressed("ui_cancel"):
				option_buttons_grid.get_children()[2].grab_focus()
		VisibilityState.MOVES:
			if event.is_action_pressed("ui_cancel"):
				change_vis_state(VisibilityState.OPTIONS)


#region Battle Setup
func bind_buttons() -> void:
	var option_buttons = get_tree().get_nodes_in_group("option_buttons")
	for b: Button in option_buttons:
		var pressed = Callable(self, "_on_option_pressed").bind(b)
		b.pressed.connect(pressed)
	
	var move_buttons = get_tree().get_nodes_in_group("move_buttons")
	for b: Button in move_buttons:
		var pressed = Callable(self, "_on_move_pressed").bind(b)
		b.pressed.connect(pressed)
	
	
func create_wild_battle(md: MonsterData, level: int) -> void:
	clear_actors()
	var enemy_monster = md.set_up(level)
	set_enemy_actor(enemy_monster)
	var player_monster = player_party[0]
	set_player_actor(player_monster)
	toggle_player()
	display_current_monsters()
	toggle_visible()

func set_player_actor(monster: Monster) -> void:
	player_actor = monster


func set_enemy_actor(monster: Monster) -> void:
	enemy_actor = monster


func set_player_party(party: Array[Monster]) -> void:
	player_party = party


func clear_actors() -> void:
	for actor in [player_actor, enemy_actor]:
		actor = null


func clear_parties() -> void:
	for party in [player_party, enemy_party]:
		party = null


func toggle_player() -> void:
	Global.toggle_player.emit()


func toggle_visible() -> void:
	visible = !visible
	processing = !processing
	if visible:
		var option_buttons = option_buttons_grid.get_children()
		option_buttons[last_focused_option].grab_focus()


func display_current_monsters() -> void:
	update_levels()
	update_names()
	update_textures()
	update_hitpoints()
	update_exp()
	update_moves()
	
	
func update_levels() -> void:
	player_level_label.text = "Lvl. %s" % [player_actor.level]
	enemy_level_label.text = "Lvl. %s" % [enemy_actor.level]
	
	
func update_names() -> void:
	player_name_label.text = player_actor.name
	enemy_name_label.text = enemy_actor.name
	
	
func update_textures() -> void:
	player_texture_rect.texture = player_actor.monster_data.texture
	enemy_texture_rect.texture = enemy_actor.monster_data.texture
	
	
func update_hitpoints() -> void:
	player_hp_bar.max_value = player_actor.max_hitpoints
	player_hp_bar.value = player_actor.current_hitpoints
	enemy_hp_bar.max_value = enemy_actor.max_hitpoints
	enemy_hp_bar.value = enemy_actor.current_hitpoints
	
	
func update_exp() -> void:
	var max_exp = Monster.EXPERIENCE_PER_LEVEL * player_actor.level
	var min_exp = Monster.EXPERIENCE_PER_LEVEL * (player_actor.level - 1)
	player_exp_bar.max_value = max_exp
	player_exp_bar.min_value = min_exp
	player_exp_bar.value = player_actor.experience
	
	
func update_moves() -> void:
	var move_labels: Array[Label] = [move_label_0, move_label_1, move_label_2, move_label_3]
	for i in range(player_actor.moves.size()):
		move_labels[i].text = player_actor.moves[i].name
		
		
func clear_battle() -> void:
	player_actor = null
	enemy_actor = null
	player_party = []
	enemy_party = []
	toggle_visible()
	toggle_player()
#endregion

#region UI Logic
func _on_option_pressed(which: Button) -> void:
	match which.name:
		"Party":
			last_focused_option = 0
		"Fight":
			last_focused_option = 1
			change_vis_state(VisibilityState.MOVES)
			focus_last_used_move(last_focused_move)
		"Run":
			last_focused_option = 2
			clear_battle()
		"Item":
			last_focused_option = 3
	
	
func _on_move_pressed(which: Button) -> void:
	match which.name:
		"Button0":
			last_focused_move = 0
		"Button1":
			last_focused_move = 1
		"Button2":
			last_focused_move = 2
		"Button3":
			last_focused_move = 3
	
	
func focus_last_used_option(value: int):
	option_buttons_grid.get_children()[value].grab_focus()
	
func focus_last_used_move(value: int):
	move_buttons_grid.get_children()[value].grab_focus()
	
func change_vis_state(state: VisibilityState) -> void:
	vis_state = state
	match state:
		VisibilityState.OPTIONS:
			move_buttons_grid.visible = false
			option_buttons_grid.visible = true
			focus_last_used_option(last_focused_option)
		VisibilityState.MOVES:
			option_buttons_grid.visible = false
			move_buttons_grid.visible = true
			focus_last_used_move(last_focused_move)
#endregion
