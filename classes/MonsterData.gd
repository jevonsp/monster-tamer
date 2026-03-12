class_name MonsterData
extends Resource
## Canonical Base Entry for a Species
@export var species: String = ""
@export var type: TypeChart.Type
@export var texture: Texture2D
@export_subgroup("Moves")
@export var moves: Dictionary[int, Move]

func set_up(level: int) -> Monster:
	"""Single entry point for Monster creation"""
	var monster = Monster.new()
	
	monster.set_monster_data(self)
	monster.set_level(level)
	monster.set_monster_moves()
	monster.set_stats()
	
	return monster
