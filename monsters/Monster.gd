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
@export var is_shiny: bool = false
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
var primary_status: StatusInstance = null
var secondary_status: StatusInstance = null
var tertiary_statuses: Array[StatusInstance] = []


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


func hold_item(item: Item) -> bool:
	if held_item == null:
		held_item = item
		return true
	return false


func add_status(instance: StatusInstance) -> bool:
	if instance == null or instance.data == null:
		return false
	if instance.source == null:
		instance.source = self
	if instance.turns_remaining < 0 and instance.data.default_duration >= 0:
		instance.turns_remaining = instance.data.default_duration
	match instance.data.slot:
		StatusData.StatusSlot.PRIMARY:
			return _set_slotted_status(&"primary", instance)
		StatusData.StatusSlot.SECONDARY:
			return _set_slotted_status(&"secondary", instance)
		StatusData.StatusSlot.TERTIARY:
			return _add_tertiary_status(instance)
	return false


func remove_status(status_id: StringName) -> bool:
	if primary_status != null and primary_status.data != null and primary_status.data.id == status_id:
		primary_status = null
		return true
	if secondary_status != null and secondary_status.data != null and secondary_status.data.id == status_id:
		secondary_status = null
		return true
	var idx := 0
	while idx < tertiary_statuses.size():
		var t: StatusInstance = tertiary_statuses[idx]
		if t != null and t.data != null and t.data.id == status_id:
			tertiary_statuses.remove_at(idx)
			return true
		idx += 1
	return false


func has_status(status_id: StringName) -> bool:
	return get_status_by_id(status_id) != null


func get_status_by_id(status_id: StringName) -> StatusInstance:
	for s in _all_active_statuses():
		if s != null and s.data != null and s.data.id == status_id:
			return s
	return null


func get_statuses_with_hook(hook: StringName) -> Array[StatusInstance]:
	var result: Array[StatusInstance] = []
	for s in _all_active_statuses():
		if s == null or s.data == null:
			continue
		if s.data.get(hook) != null:
			result.append(s)
	return result


func get_effective_stat(stat: Monster.Stat) -> float:
	var base: float = float(_get_base_stat(stat))
	var multi: float = 1.0
	if stat_stages_and_multis != null:
		multi *= float(stat_stages_and_multis.stat_multipliers.get(stat, 1.0))
		var stage: int = int(stat_stages_and_multis.stat_stages.get(stat, 0))
		multi *= _stat_stage_multiplier(stage)
	multi *= _status_stat_multiplier(stat)
	return base * multi


func _all_active_statuses() -> Array[StatusInstance]:
	var arr: Array[StatusInstance] = []
	if primary_status != null:
		arr.append(primary_status)
	if secondary_status != null:
		arr.append(secondary_status)
	for t: StatusInstance in tertiary_statuses:
		if t != null:
			arr.append(t)
	return arr


func _set_slotted_status(slot_key: StringName, incoming: StatusInstance) -> bool:
	var existing: StatusInstance = primary_status if slot_key == &"primary" else secondary_status
	if existing != null:
		match incoming.data.stack_policy:
			StatusData.StackPolicy.REJECT:
				return false
			StatusData.StackPolicy.REFRESH:
				existing.turns_remaining = incoming.data.default_duration
				existing.stacks = mini(existing.stacks + 1, 99)
				return true
			StatusData.StackPolicy.REPLACE:
				pass
	if slot_key == &"primary":
		primary_status = incoming
	else:
		secondary_status = incoming
	return true


func _add_tertiary_status(incoming: StatusInstance) -> bool:
	var existing: StatusInstance = get_status_by_id(incoming.data.id)
	if existing != null:
		match incoming.data.stack_policy:
			StatusData.StackPolicy.REJECT:
				return false
			StatusData.StackPolicy.REFRESH:
				existing.turns_remaining = incoming.data.default_duration
				existing.stacks = mini(existing.stacks + 1, 99)
				return true
			StatusData.StackPolicy.REPLACE:
				var idx: int = tertiary_statuses.find(existing)
				tertiary_statuses[idx] = incoming
				return true
	tertiary_statuses.append(incoming)
	return true


func _get_base_stat(stat: Monster.Stat) -> int:
	match stat:
		Monster.Stat.ATTACK:
			return attack
		Monster.Stat.DEFENSE:
			return defense
		Monster.Stat.SPECIAL_ATTACK:
			return special_attack
		Monster.Stat.SPECIAL_DEFENSE:
			return special_defense
		Monster.Stat.SPEED:
			return speed
		Monster.Stat.HITPOINTS:
			return max_hitpoints
	return 0


func _stat_stage_multiplier(stage: int) -> float:
	if stage == 0:
		return 1.0
	if stage > 0:
		return float(2 + stage) / 2.0
	return 2.0 / float(2 - stage)


func _status_stat_multiplier(stat: Monster.Stat) -> float:
	var multi: float = 1.0
	for s: StatusInstance in _all_active_statuses():
		if s == null or s.data == null:
			continue
		if s.data.stat_multipliers.has(stat):
			multi *= float(s.data.stat_multipliers[stat])
	return multi
