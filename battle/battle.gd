extends CanvasLayer

var player_actor: Monster
var enemy_actor: Monster
var player_party: Array[Monster] = []
var enemy_party: Array[Monster] = []

@onready var button_0: Button = $Content/Buttons/Button0
@onready var move_label_0: Label = $Content/Buttons/Button0/Label
@onready var move_label_1: Label = $Content/Buttons/Button1/Label
@onready var move_label_2: Label = $Content/Buttons/Button2/Label
@onready var move_label_3: Label = $Content/Buttons/Button3/Label
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


func create_wild_battle(md: MonsterData, level: int) -> void:
	clear_actors()
	var enemy_monster = md.set_up(level)
	set_enemy_actor(enemy_monster)
	var player_monster = player_party[0]
	set_player_actor(player_monster)
	toggle_player()
	display_current_monsters()
	toggle_visible()
	button_0.grab_focus()


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
		
