class_name MonsterData
extends Resource

enum Gender { GENDERLESS, MALE, FEMALE }

@export var species: String = ""
@export_multiline var description: String = ""
@export var primary_type: TypeChart.Type
@export var secondary_type: TypeChart.Type
@export var base_front_texture: Texture2D
@export var base_back_texture: Texture2D
@export var shiny_front_texture: Texture2D
@export var shiny_back_texture: Texture2D
@export_subgroup("Moves")
@export var starting_moves: Array[Move] = []
@export var level_up_moves: Dictionary[int, Move] = { }
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
@export var male_ratio: int = 1
@export var female_ratio: int = 1


func set_up(level: int) -> Monster:
	var monster: Monster = Monster.new()
	monster.set_monster_data(self)
	monster.set_level(level)
	monster.set_monster_moves()
	create_learn_set()
	monster.set_stats()
	#monster.create_stat_multis()
	monster.current_hitpoints = monster.max_hitpoints

	return monster


func can_learn_move(move: Move) -> bool:
	return move in learn_set


func interpret_gender() -> Gender:
	match [male_ratio, female_ratio]:
		[0, 0]:
			return Gender.GENDERLESS
		[_, 0]:
			return Gender.MALE
		[0, _]:
			return Gender.FEMALE
		_:
			var roll: int = randi_range(0, male_ratio + female_ratio - 1)
			return Gender.MALE if roll < male_ratio else Gender.FEMALE


func create_learn_set() -> void:
	for move in starting_moves:
		learn_set.append(move)
	for level in level_up_moves:
		learn_set.append(level_up_moves[level])
