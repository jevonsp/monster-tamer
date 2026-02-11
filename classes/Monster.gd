extends Resource
class_name Monster
static var EXPERIENCE_PER_LEVEL = 50
@export var monster_data: MonsterData
@export var name: String = ""

@export var level: int = 1
@export var experience: int = 0

@export var max_hitpoints: int = 10
@export var current_hitpoints: int
@export var attack: int = 1
@export var defense: int = 1
@export var speed: int = 1

@export var moves: Array = []

func set_monster_data(md: MonsterData) -> void:
	monster_data = md
	name = monster_data.species


func set_level(l: int) -> void:
	"""Always use this to set level. Keeps EXP correct"""
	level = l
	experience = EXPERIENCE_PER_LEVEL * (level - 1)


func set_monster_moves() -> void:
	var move_level = monster_data.move_level
	var move_gained = monster_data.move_gained
	var moves_to_gain: Array[Move] = [null, null, null, null]
	for i in range(len(move_gained)):
		if move_level[i] <= level:
			moves_to_gain.pop_back()
			moves_to_gain.push_front(move_gained[i])
	moves = moves_to_gain
	print_debug("%s moves:" % [name])
	for m in moves:
		if m != null:
			print("   ", m.name)
		else:
			print("    Empty slot")


func set_stats() -> void:
	current_hitpoints = max_hitpoints



func take_damage(amount: int) -> void:
	pass
