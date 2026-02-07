extends Resource
class_name Monster

@export var monster_data: MonsterData
@export var name: String = ""

@export var level: int = 1
@export var max_hitpoints: int = 10
@export var current_hitpoints: int
@export var attack: int = 1
@export var defense: int = 1
@export var speed: int = 1


func set_monster_data(md: MonsterData) -> void:
	monster_data = md
	name = monster_data.species
