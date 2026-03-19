class_name MonsterData
extends Resource
## Canonical Base Entry for a Species
@export var species: String = ""
@export var type: TypeChart.Type
@export var texture: Texture2D
@export_subgroup("Moves")
@export var starting_moves: Array[Move]
@export var level_up_moves: Dictionary[int, Move]
@export_subgroup("Base Stats")
@export var base_hitpoints: int = 50 
@export var base_attack: int = 50
@export var base_special_attack: int = 50
@export var base_defense: int = 50
@export var base_special_defense: int = 50
@export var base_speed: int = 50

func set_up(level: int) -> Monster:
	"""Single entry point for Monster creation"""
	var monster = Monster.new()
	
	monster.set_monster_data(self)
	monster.set_level(level)
	monster.set_monster_moves()
	monster.set_stats()
	monster.create_stat_multis()
	monster.current_hitpoints = monster.max_hitpoints
	
	return monster
