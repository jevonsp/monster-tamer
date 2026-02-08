extends Resource
class_name Monster

@export var monster_data: MonsterData
@export var name: String = ""

@export var level: int = 1
@export var experience: int = 0

@export var max_hitpoints: int = 10
@export var current_hitpoints: int
@export var attack: int = 1
@export var defense: int = 1
@export var speed: int = 1

@export var moves: Array[Move] = []

func set_monster_data(md: MonsterData) -> void:
	monster_data = md
	name = monster_data.species


func set_level(l: int) -> void:
	"""Always use this to set level. Keeps EXP correct"""
	level = l
	experience = 50 * level


func set_monster_moves() -> void:
	var move_level = monster_data.move_level
	var move_gained = monster_data.move_gained
	var moves_to_gain: Array[Move] = []
	for i in range(len(move_gained)):
		if move_level[i] <= level:
			if moves.size() < 4:
				moves_to_gain.append(move_gained[i])
			else:
				moves_to_gain.pop_back()
				moves_to_gain.push_front(move_gained[i])
	moves = moves_to_gain
	print_debug("%s moves:" % [name])
	for m in moves:
		print("   ", m.name)
