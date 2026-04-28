class_name Monster
extends Resource

enum Stat {
	NONE,
	ATTACK,
	SPECIAL_ATTACK,
	DEFENSE,
	SPECIAL_DEFENSE,
	SPEED,
	ACCURACY,
	EVASION,
	CRITICAL,
	HITPOINTS,
}
enum LevelUpMoveResult {
	AUTO_LEARNED,
	NEEDS_SWAP,
}

const EXPERIENCE_PER_LEVEL: int = 50

@export var monster_data: MonsterData
@export var name: String = ""
@export var primary_type: Variant = null
@export var secondary_type: Variant = null
@export var gender: MonsterData.Gender
@export var nature: String = ""
@export var level: int = 1
@export var experience: int = 0
@export var max_hitpoints: int
@export var current_hitpoints: int
@export var attack: int = 1
@export var special_attack: int = 1
@export var defense: int = 1
@export var special_defense: int = 1
@export var speed: int = 1
@export var moves: Array[Move] = []
@export var move_pp: Dictionary[Move, int] = { }
@export var is_player_monster: bool = false
@export var is_fainted: bool = false
@export var is_disabled: bool = false
@export var is_captured: bool = false
@export var was_active_in_battle: bool = false
@export var player_in_battle: bool = false
@export var held_item: Item
@export var stat_stages_and_multis: MonsterStatMultipliers = null

var is_able_to_fight: bool:
	get:
		return not is_fainted and not is_captured
var statuses: Array[StatusInstance] = []


func set_monster_data(monster_data_resource: MonsterData) -> void:
	monster_data = monster_data_resource
	set_type()
	name = monster_data.species
	gender = monster_data.interpret_gender()
	nature = NatureChart.get_random_nature()


func set_type() -> void:
	primary_type = monster_data.primary_type
	if monster_data.secondary_type != TypeChart.Type.NONE:
		secondary_type = monster_data.secondary_type


func set_level(new_level: int) -> void:
	level = new_level
	experience = EXPERIENCE_PER_LEVEL * (level - 1)


func set_monster_moves() -> void:
	var moves_to_gain: Array[Move] = monster_data.starting_moves
	while moves_to_gain.size() < 4:
		moves_to_gain.append(null)

	for key_level: int in monster_data.level_up_moves.keys():
		var move: Move = monster_data.level_up_moves[key_level]
		if key_level <= level:
			moves_to_gain.pop_back()
			moves_to_gain.push_front(move)
	moves = moves_to_gain
	for move in moves:
		if move:
			set_pp(move)


func set_monster_name(has_nickname: bool, nick_name: Variant = null) -> void:
	if has_nickname:
		name = nick_name
	else:
		name = monster_data.species


func set_stats() -> void:
	var stats: Array[int] = [attack, defense, special_attack, special_defense, speed]
	var stat_enums: Array[Monster.Stat] = [
		Monster.Stat.ATTACK,
		Monster.Stat.DEFENSE,
		Monster.Stat.SPECIAL_ATTACK,
		Monster.Stat.SPECIAL_DEFENSE,
		Monster.Stat.SPEED,
	]
	var base_stats: Array[int] = [
		monster_data.base_attack,
		monster_data.base_defense,
		monster_data.base_special_attack,
		monster_data.base_special_defense,
		monster_data.base_speed,
	]
	for i in range(stats.size()):
		stats[i] = ceili(
			(int((2 * base_stats[i] * level) / 100.0) + 5)
			* NatureChart.get_nature_multiplier(nature, stat_enums[i]),
		)

	max_hitpoints = int((2 * monster_data.base_hitpoints * level) / 100.0) + level + 10


func set_pp(move: Move) -> void:
	move_pp[move] = move.base_pp
