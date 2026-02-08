extends Resource
class_name MonsterData

@export var species: String = ""
@export var texture: Texture2D
@export_subgroup("Moves")
@export var move_level: Array[int] = []
@export var move_gained: Array[Move] = []


func set_up(level: int) -> Monster:
	"""Single entry point for Monster creation"""
	var monster = Monster.new()
	
	monster.set_monster_data(self)
	monster.set_level(level)
	monster.set_monster_moves()
	
	return monster
