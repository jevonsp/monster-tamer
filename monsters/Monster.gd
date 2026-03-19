class_name Monster
extends Resource
## An instance of a monster
static var EXPERIENCE_PER_LEVEL = 50
enum Stat { ATTACK, SPECIAL_ATTACK, DEFENSE, SPECIAL_DEFENSE, SPEED, ACCURACY, EVASION, CRITICAL }
@export var monster_data: MonsterData
@export var name: String = ""
@export var type: TypeChart.Type

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
@export var is_player_monster: bool = false
@export var is_fainted: bool = false
@export var is_captured: bool = false
@export var is_able_to_act: bool = true
@export var was_active_in_battle: bool = false
@export var player_in_battle: bool = false

@export var stat_multis: MonsterStatMultipliers = null

var is_able_to_fight: bool:
	get: return not is_fainted and not is_captured
var statuses: Array[StatusInstance] = []

func set_monster_data(md: MonsterData) -> void:
	monster_data = md
	type = monster_data.type
	name = monster_data.species


func set_level(l: int) -> void:
	"""Always use this to set level. Keeps EXP correct"""
	level = l
	experience = EXPERIENCE_PER_LEVEL * (level - 1)


func set_monster_moves() -> void:
	var moves_to_gain: Array[Move] = [null, null, null, null]
	for key_level in monster_data.moves.keys():
		var move = monster_data.moves[key_level]
		if key_level <= level:
			moves_to_gain.pop_back()
			moves_to_gain.push_front(move)
	moves = moves_to_gain


func set_stats() -> void:
	var stats = [attack, defense, special_attack, special_defense, speed]
	var base_stats = [
		monster_data.base_attack, 
		monster_data.base_defense, 
		monster_data.base_special_attack, 
		monster_data.base_special_defense, 
		monster_data.base_speed,
	]
	for i in range(5):
		stats[i] = int((2 * base_stats[i] * level) / 100.0) + 5
	
	max_hitpoints = int((2 * monster_data.base_hitpoints * level) / 100.0) + level + 10


func create_stat_multis() -> void:
	var monster_stat_multis = MonsterStatMultipliers.new()
	stat_multis = monster_stat_multis


func get_stat_stage_multi(stat: Stat) -> float:
	var stage: int = stat_multis.stat_stages.get(stat, 0)
	
	match stat:
		Stat.ACCURACY, Stat.EVASION:
			return MonsterStatTable.special_stat_multis[stage]
		Stat.CRITICAL:
			return MonsterStatTable.critical_stage_multi[stage]
		_:
			return MonsterStatTable.normal_stat_multis[stage]


func take_damage(amount: int) -> void:
	current_hitpoints = max(0, current_hitpoints - amount)
	print_debug("BATTLE: %s take_damage amount=%s -> hp=%s/%s" % [name, amount, current_hitpoints, max_hitpoints])
	Global.send_hitpoints_change.emit(self, current_hitpoints)
	await Global.hitpoints_animation_complete


func check_faint() -> void:
	if current_hitpoints <= 0:
		print_debug("BATTLE: %s check_faint -> faint() current_hp=%s" % [name, current_hitpoints])
		await faint()


func add_status(status_data: StatusData, duration: int = -1, context: BattleContext = null) -> void:
	var instance := StatusInstance.new(status_data, self, duration)
	statuses.append(instance)
	if context != null:
		await instance.on_apply(context)


func remove_status(instance: StatusInstance) -> void:
	if instance in statuses:
		instance.on_remove(null)
		statuses.erase(instance)


func has_status(status_name: String) -> bool:
	for s in statuses:
		if s.data and s.data.status_name == status_name:
			return true
	return false


func tick_statuses_start(context: BattleContext) -> void:
	var to_remove: Array[StatusInstance] = []
	for status in statuses:
		await status.on_turn_start(context)
		if status.is_expired():
			to_remove.append(status)

	for s in to_remove:
		if s.data != null:
			await s.on_remove(context)
		statuses.erase(s)


func tick_statuses_end(context: BattleContext) -> void:
	var to_remove: Array[StatusInstance] = []
	for status in statuses:
		await status.on_turn_end(context)
		status.tick_duration()
		if status.is_expired():
			to_remove.append(status)
	for s in to_remove:
		if s.data != null:
			await s.on_remove(context)
		statuses.erase(s)


func faint():
	if is_fainted:
		return
	print_debug("BATTLE: %s faint() start is_player=%s is_fainted=%s" % [name, is_player_monster, is_fainted])
	is_fainted = true
	Global.send_monster_fainted.emit(self)
	print_debug("BATTLE: %s send_monster_fainted emitted" % [name])
	
	
func heal(amount: int, revives: bool = false) -> void:
	current_hitpoints = min(current_hitpoints + amount, max_hitpoints)
	Global.send_hitpoints_change.emit(self, current_hitpoints)
	await Global.hitpoints_animation_complete
	if revives:
		is_fainted = false
	
	
func fully_heal_and_revive() -> void:
	current_hitpoints = max_hitpoints
	Global.send_hitpoints_change.emit(self, current_hitpoints)
	is_fainted = false
	
	
func gain_exp(amount: int, in_battle: bool = false) -> void:
	if is_fainted:
		return
	print_debug("EXP: %s gain_exp amount=%s in_battle=%s" % [name, amount, in_battle])
	var remaining_exp = amount
	while remaining_exp > 0:
		var exp_left = get_next_level_exp() - experience
		var exp_to_gain = min(remaining_exp, exp_left)
		remaining_exp -= exp_to_gain
		experience += exp_to_gain
		Global.monster_gained_experience.emit(self, exp_to_gain)
		if in_battle:
			print_debug("EXP: %s waiting for experience_animation_complete" % [name])
			await Global.experience_animation_complete
			print_debug("EXP: %s experience_animation_complete" % [name])
		if experience >= get_next_level_exp():
			print_debug("EXP: %s level up triggered" % [name])
			await gain_level(1, in_battle)


func give(item: Item) -> void:
	print_debug("%s would add %s as held item" % [name, item.name])


func get_current_level_exp() -> int:
	return EXPERIENCE_PER_LEVEL * (level - 1)
	
	
func get_next_level_exp() -> int:
	return EXPERIENCE_PER_LEVEL * level


func gain_level(amount: int = 1, in_battle: bool = false) -> void:
	level += amount
	set_stats()
	print_debug("EXP: %s gain_level amount=%s -> level=%s" % [name, amount, level])
	Global.monster_gained_level.emit(self, amount)
	if in_battle:
		print_debug("EXP: %s waiting for battle-side level-up resolution" % [name])
		Global.request_battle_level_up_resolution.emit(self, amount)
		await Global.battle_level_up_resolution_complete
		print_debug("EXP: %s battle-side level-up resolution complete" % [name])
	print_debug("EXP: %s gain_level complete" % [name])
	
	
func check_should_gain_moves() -> bool:
	return monster_data.moves.has(level)


func get_move_to_learn() -> Move:
	return monster_data.moves.get(level)
	
	
func get_learn_index() -> int:
	for i in range(4):
		if moves[i] == null:
			return i
	return -1
	
	
func learn_move(move: Move, index: int) -> void:
	print_debug("EXP: %s learn_move %s at index=%s" % [name, move.name, index])
	moves[index] = move
	
	
func attempt_catch(item: Item, _actor: Monster) -> Dictionary:
	var _catch_rate = item.catch_effect.catch_rate_modifier
	var result = {
		"times": 3,
		"success": true
	}
	return result
