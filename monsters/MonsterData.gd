class_name MonsterData
extends Resource

@export var species: String = ""
@export_multiline var description: String = ""
@export var primary_type: TypeChart.Type
@export var secondary_type: TypeChart.Type
@export var texture: Texture2D
@export_subgroup("Moves")
@export var starting_moves: Array[Move] = []
@export var level_up_moves: Dictionary[int, Move] = {}
@export var learn_set: Array[Move] = []
@export_subgroup("Base Stats")
@export var base_hitpoints: int = 50
@export var base_attack: int = 50
@export var base_special_attack: int = 50
@export var base_defense: int = 50
@export var base_special_defense: int = 50
@export var base_speed: int = 50
@export_subgroup("Other Stats")
@export var catch_rate: int = 200

func set_up(level: int) -> Monster:
	var monster: Monster = Monster.new()
	monster.set_monster_data(self)
	monster.set_level(level)
	monster.set_monster_moves()
	monster.set_stats()
	monster.create_stat_multis()
	monster.current_hitpoints = monster.max_hitpoints

	return monster


func can_learn_move(move: Move) -> bool:
	return move in learn_set
