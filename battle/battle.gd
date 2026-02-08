extends CanvasLayer

var player_actor: Monster
var enemy_actor: Monster
var enemy_party: Array[Monster] = []

func _ready() -> void:
	Global.wild_battle_requested.connect(create_wild_battle)


func create_wild_battle(md: MonsterData, level: int) -> void:
	clear_actors()
	var monster = md.set_up(level)
	set_enemy_actor(monster)
	toggle_player()
	toggle_visible()

func set_player_actor(monster: Monster) -> void:
	player_actor = monster
	

func set_enemy_actor(monster: Monster) -> void:
	enemy_actor = monster


func clear_actors() -> void:
	for actor in [player_actor, enemy_actor]:
		actor = null
		

func toggle_player() -> void:
	Global.toggle_player.emit()

func toggle_visible() -> void:
	visible = !visible
