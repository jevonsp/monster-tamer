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
#region Stat Dicts
var stat_stages: Dictionary = {
	Stat.ATTACK: 0,
	Stat.SPECIAL_ATTACK: 0,
	Stat.DEFENSE: 0,
	Stat.SPECIAL_DEFENSE: 0,
	Stat.SPEED: 0,
	Stat.ACCURACY: 0,
	Stat.EVASION: 0,
	Stat.CRITICAL: 0,
}
var stat_multipliers: Dictionary = {
	Stat.ATTACK: 1.0,
	Stat.SPECIAL_ATTACK: 1.0,
	Stat.DEFENSE: 1.0,
	Stat.SPECIAL_DEFENSE: 1.0,
	Stat.SPEED: 1.0,
	Stat.ACCURACY: 1.0,
	Stat.EVASION: 1.0,
}
var stat_properties: Dictionary = {
	Stat.ATTACK: &"attack",
	Stat.SPECIAL_ATTACK: &"special_attack",
	Stat.DEFENSE: &"defense",
	Stat.SPECIAL_DEFENSE: &"special_defense",
	Stat.SPEED: &"speed",
}
var normal_stat_multis: Dictionary = {
	-6: 2/8.0,-5: 2/7.0,-4: 2/6.0,-3: 2/5.0,-2: 2/4.0,-1: 2/3.0,
	0: 2/2.0,
	1: 3/2.0, 2: 4/2.0, 3: 5/2.0, 4: 6/2.0, 5: 7/2.0, 6: 8/2.0,
}
var special_stat_multis: Dictionary = {
	-6: 3/9.0, -5: 3/8.0, -4: 3/7.0, -3: 3/6.0, -2: 3/5.0, -1: 3/4.0,
	0: 3/3.0,
	1: 4/3.0, 2: 5/3.0, 3: 6/3.0, 4: 7/3.0, 5: 8/3.0, 6: 9/3.0,
}
var critical_stage_multi: Dictionary = {
	0: 1/16.0,
	1: 1/8.0,
	2: 1/4.0,
	3: 1/2.0,
	4: 1
}
#endregion

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
	attack = int((2 * monster_data.base_attack * level) / 100.0) + 5
	defense = int((2 * monster_data.base_defense * level) / 100.0) + 5
	special_attack = int((2 * monster_data.base_special_attack * level) / 100.0) + 5
	special_defense = int((2 * monster_data.base_special_defense * level) / 100.0) + 5
	speed = int((2 * monster_data.base_speed * level) / 100.0) + 5
	
	max_hitpoints = int((2 * monster_data.base_hitpoints * level) / 100.0) + level + 10


func get_stat_stage_multi(stat: Stat) -> float:
	var stage: int = stat_stages.get(stat, 0)
	
	match stat:
		Stat.ACCURACY, Stat.EVASION:
			return special_stat_multis[stage]
		Stat.CRITICAL:
			return critical_stage_multi[stage]
		_:
			return normal_stat_multis[stage]


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
	var ta: Array[String] = ["%s fainted!" % [name]]
	if Player.in_battle:
		Global.send_text_box.emit(null, ta, true, false, false)
	else:
		Global.send_text_box.emit(null, ta, false, false, true)
	await Global.text_box_complete
	print_debug("BATTLE: %s faint text complete" % [name])
	if not is_player_monster:
		print_debug("BATTLE: %s send_monster_death_experience amount=%s" % [name, EXPERIENCE_PER_LEVEL * level])
		Global.send_monster_death_experience.emit(EXPERIENCE_PER_LEVEL * level)
	
	
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
			await gain_level()


func give(item: Item) -> void:
	print_debug("%s would add %s as held item" % [name, item.name])


func get_current_level_exp() -> int:
	return EXPERIENCE_PER_LEVEL * (level - 1)
	
	
func get_next_level_exp() -> int:
	return EXPERIENCE_PER_LEVEL * level


func gain_level(amount: int = 1) -> void:
	level += amount
	print_debug("EXP: %s gain_level amount=%s -> level=%s" % [name, amount, level])
	Global.monster_gained_level.emit(self, amount)
	var ta: Array[String] = ["%s leveled up to %s." % [name, level]]
	Global.send_text_box.emit(null, ta, false, false, false)
	await Global.text_box_complete
	print_debug("EXP: %s level-up text complete" % [name])
	if check_should_gain_moves():
		print_debug("EXP: %s should gain move at level=%s" % [name, level])
		if get_learn_index() >= 0:
			print_debug("EXP: %s learning move in empty slot index=%s" % [name, get_learn_index()])
			await learn_move(monster_data.moves[level], get_learn_index())
		else:
			print_debug("EXP: %s has 4 moves; entering decide_move" % [name])
			await decide_move(monster_data.moves[level])
	set_stats()
	print_debug("EXP: %s gain_level complete" % [name])
	
	
func check_should_gain_moves() -> bool:
	if monster_data.moves.has(level):
		return true
	return false
	
	
func get_learn_index() -> int:
	for i in range(4):
		if moves[i] == null:
			return i
	return -1
	
	
func decide_move(move: Move) -> void:
	var decided = false
	while not decided:
		var ta: Array[String] = \
				["%s is trying to learn %s, but already knows four moves. Delete one?" % [name, move.name]]
		Global.send_text_box.emit(self, ta, false, true, false)
		var answer = await Global.answer_given
		if answer:
			decided = true
			Global.request_summary_learn_move.emit(move)
			Global.request_open_summary.emit(self)
			print_debug("EXP: %s waiting for move_learning_finished" % [name])
			await Global.move_learning_finished
			print_debug("EXP: %s move_learning_finished" % [name])
		else:
			ta = ["Are you sure you want %s to stop learning %s" % [name, move.name]]
			Global.send_text_box.emit(self, ta, false, true, false)
			var confirmed_skip = await Global.answer_given
			if confirmed_skip:
				decided = true
				ta = ["%s did not learn %s" % [name, move.name]]
				Global.send_text_box.emit(self, ta, false, false, false)
	
	
func learn_move(move: Move, index: int) -> void:
	print_debug("EXP: %s learn_move %s at index=%s" % [name, move.name, index])
	moves[index] = move
	var ta: Array[String] = ["%s learned %s." % [name, move.name]]
	if Player.in_battle:
		Global.send_text_box.emit(self, ta, false, false, false)
	else:
		Global.send_text_box.emit(self, ta, false, false, false)
		
	await Global.text_box_complete
	print_debug("EXP: %s learn_move text complete" % [name])
	
	
func attempt_catch(item: Item, _actor: Monster) -> Dictionary:
	var _catch_rate = item.catch_effect.catch_rate_modifier
	var result = {
		"times": 3,
		"success": true
	}
	return result
	
