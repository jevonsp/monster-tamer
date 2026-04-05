class_name Monster
extends Resource

enum StatusApplyResult {
	APPLIED,
	REFRESHED,
	BLOCKED_DUPLICATE,
	BLOCKED_SLOT_CONFLICT,
}
enum BoostApplyResult { APPLIED, BLOCKED }
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
@export var is_captured: bool = false
@export var was_active_in_battle: bool = false
@export var player_in_battle: bool = false
@export var held_item: Item
@export var stat_stages_and_multis: MonsterStatMultipliers = null

var is_able_to_fight: bool:
	get:
		return not is_fainted and not is_captured
var statuses: Array[StatusInstance] = []

enum LevelUpMoveResult {
	AUTO_LEARNED,
	NEEDS_SWAP,
}


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


func get_stat(stat: Stat) -> int:
	var property_name: StringName = MonsterStatTable.stat_properties[stat]
	var base: int = int(get(property_name))
	if held_item and held_item.held_effect:
		match held_item.held_effect.boost_type:
			HeldEffect.BoostType.FLAT:
				return base + held_item.held_effect.flat_boost_amount
			HeldEffect.BoostType.PERCENTAGE:
				return int(base * held_item.held_effect.percentage_boost_amount)
	return base


func create_stat_multis() -> void:
	var new: MonsterStatMultipliers = MonsterStatMultipliers.new()
	stat_stages_and_multis = new


func get_stat_stage_multi(stat: Stat) -> float:
	var stage: int = stat_stages_and_multis.stat_stages.get(stat, 0)

	match stat:
		Stat.ACCURACY, Stat.EVASION:
			return MonsterStatTable.special_stat_multis[stage]
		Stat.CRITICAL:
			return MonsterStatTable.critical_stage_multi[stage]
		_:
			return MonsterStatTable.normal_stat_multis[stage]


func take_damage(amount: int) -> void:
	current_hitpoints = max(0, current_hitpoints - amount)
	Battle.send_hitpoints_change.emit(self, current_hitpoints)
	await Battle.hitpoints_animation_complete


func check_faint() -> void:
	if current_hitpoints <= 0:
		faint()


func add_status(
		status_data: StatusData,
		duration: int = -1,
		context: BattleContext = null,
) -> StatusApplyResult:
	var resolved_duration := duration if duration > 0 else status_data.default_duration
	var existing_status := get_status_by_id(status_data.get_identifier())

	if existing_status != null:
		if status_data.status_slot == StatusData.StatusSlot.SEPARATE:
			existing_status.remaining_turns = resolved_duration
			return StatusApplyResult.REFRESHED
		return StatusApplyResult.BLOCKED_DUPLICATE

	var conflicting_status := get_status_in_slot(status_data.status_slot)
	if conflicting_status != null and status_data.status_slot == StatusData.StatusSlot.MAIN:
		return StatusApplyResult.BLOCKED_SLOT_CONFLICT

	var instance := StatusInstance.new(status_data, self, resolved_duration)
	statuses.append(instance)
	if context != null:
		await instance.on_apply(context)
	return StatusApplyResult.APPLIED


func boost_stat(stat: Stat, amount: int) -> BoostApplyResult:
	var entry = stat_stages_and_multis.stat_stages[stat]
	if amount > 0 and (entry + amount > 6 or entry + amount < -6):
		return BoostApplyResult.BLOCKED
	entry += clamp(amount, -6, 6)
	stat_stages_and_multis.stat_stages[stat] = entry
	return BoostApplyResult.APPLIED


func remove_status(instance: StatusInstance) -> void:
	if instance in statuses:
		instance.on_remove(null)
		statuses.erase(instance)


func has_status(status_name: String) -> bool:
	for status: StatusInstance in statuses:
		if status.data and status.data.status_name == status_name:
			return true
	return false


func has_status_id(status_identifier: String) -> bool:
	for status: StatusInstance in statuses:
		if status.data and status.data.get_identifier() == status_identifier:
			return true
	return false


func get_status_by_id(status_identifier: String) -> StatusInstance:
	for status in statuses:
		if status.data and status.data.get_identifier() == status_identifier:
			return status
	return null


func has_status_in_slot(status_slot: StatusData.StatusSlot) -> bool:
	return get_status_in_slot(status_slot) != null


func get_status_in_slot(status_slot: StatusData.StatusSlot) -> StatusInstance:
	for status in statuses:
		if status.data and status.data.status_slot == status_slot:
			return status
	return null


func reset_status_turn_state() -> void:
	for status in statuses:
		status.reset_turn_state()


func get_effective_stat(stat: Stat) -> float:
	var base_value: float = 1.0
	if MonsterStatTable.stat_properties.has(stat):
		base_value = float(get(MonsterStatTable.stat_properties[stat]))

	var value := base_value
	if stat_stages_and_multis != null:
		value *= get_stat_stage_multi(stat)
		value *= stat_stages_and_multis.stat_multipliers.get(stat, 1.0)

	for status in statuses:
		value = status.modify_effective_stat(stat, value)

	return value


func get_effective_speed() -> float:
	return get_effective_stat(Stat.SPEED)


func can_attempt_action(context: BattleContext) -> bool:
	for status in statuses:
		if not status.can_attempt_action(context):
			return false
	return true


func get_action_block_text() -> Array[String]:
	for status in statuses:
		var text := status.get_action_block_text()
		if not text.is_empty():
			return text
	return []


func has_action_override(context: BattleContext, chosen_action) -> bool:
	for status in statuses:
		if status.has_action_override(context, chosen_action):
			return true
	return false


func execute_action_override(target: Monster, context: BattleContext, chosen_action) -> void:
	for status in statuses:
		if status.has_action_override(context, chosen_action):
			await status.execute_action_override(target, context, chosen_action)
			return


func tick_statuses_start(context: BattleContext) -> void:
	var to_remove: Array[StatusInstance] = []
	for status: StatusInstance in statuses:
		await status.on_turn_start(context)
		if status.is_expired():
			to_remove.append(status)

	for status: StatusInstance in to_remove:
		if status.data != null:
			await status.on_remove(context)
		statuses.erase(status)


func tick_statuses_end(context: BattleContext) -> void:
	var to_remove: Array[StatusInstance] = []
	for status: StatusInstance in statuses:
		await status.on_turn_end(context)
		status.tick_duration()
		if status.is_expired():
			to_remove.append(status)
	for status: StatusInstance in to_remove:
		if status.data != null:
			await status.on_remove(context)
		statuses.erase(status)


func faint() -> void:
	if is_fainted:
		return
	is_fainted = true
	Battle.send_monster_fainted.emit(self)


func heal(amount: int, revives: bool = false) -> void:
	current_hitpoints = min(current_hitpoints + amount, max_hitpoints)
	Battle.send_hitpoints_change.emit(self, current_hitpoints)
	await Battle.hitpoints_animation_complete
	if revives:
		is_fainted = false


func fully_heal_and_revive() -> void:
	current_hitpoints = max_hitpoints
	Battle.send_hitpoints_change.emit(self, current_hitpoints)
	is_fainted = false


func gain_exp(amount: int, in_battle: bool = false) -> void:
	if is_fainted:
		return
	var remaining_exp: int = amount
	while remaining_exp > 0:
		var exp_left: int = get_next_level_exp() - experience
		var exp_to_gain: int = min(remaining_exp, exp_left)
		remaining_exp -= exp_to_gain
		experience += exp_to_gain
		Battle.monster_gained_experience.emit(self, exp_to_gain)
		if in_battle:
			await Battle.experience_animation_complete
		if experience >= get_next_level_exp():
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
	Battle.monster_gained_level.emit(self, amount)
	if in_battle:
		Battle.request_battle_level_up_resolution.emit(self, amount)
		await Battle.battle_level_up_resolution_complete
	else:
		if check_should_gain_moves():
			var move_to_learn: Move = get_move_to_learn()
			if move_to_learn != null:
				if learn_level_up_move(move_to_learn) == LevelUpMoveResult.NEEDS_SWAP:
					Party.request_summary_move_learning.emit(self, move_to_learn)
					await Ui.move_learning_finished
				else:
					await MoveLearningService.show_move_learned_message(self, move_to_learn)
	var entry = EvolutionHandler.check_monster_evolve(self, Entry.Trigger.LEVEL_UP)
	if entry:
		EvolutionHandler.request_evolve(self, entry)
		await EvolutionHandler.evolution_process_finished


func check_should_gain_moves() -> bool:
	return monster_data.level_up_moves.has(level)


func get_move_to_learn() -> Move:
	return monster_data.level_up_moves.get(level)


func get_learn_index() -> int:
	for i in range(4):
		if moves[i] == null:
			return i
	return -1


func learn_move(move: Move, index: int) -> void:
	if moves[index] != null:
		move_pp.erase(move)
	moves[index] = move
	set_pp(move)


func learn_level_up_move(move: Move) -> LevelUpMoveResult:
	var index := get_learn_index()
	if index >= 0:
		learn_move(move, index)
		return LevelUpMoveResult.AUTO_LEARNED
	return LevelUpMoveResult.NEEDS_SWAP


func set_pp(move: Move) -> void:
	move_pp[move] = move.base_pp


func has_pp(move: Move) -> bool:
	if move == null:
		return false
	if not move_pp.has(move):
		return false
	return move_pp[move] > 0


func decrement_pp(move: Move, amount: int = 1) -> void:
	if move == null or not move_pp.has(move):
		return
	move_pp[move] -= amount


func restore_pp() -> void:
	for move: Move in move_pp.keys():
		move_pp[move] = move.base_pp


func attempt_catch(item: Item, _actor: Monster) -> Dictionary:
	var ball_bonus: float = item.catch_effect.catch_rate_modifier
	var status_bonus: float = get_status_catch_bonus()
	var hp_max: int = max_hitpoints
	var hp_curr: int = current_hitpoints
	var modified_catch_rate: int = min(
		255,
		(3 * hp_max - 2 * hp_curr) / (3 * float(hp_max)) * ball_bonus * status_bonus,
	)
	var shake_probability: int = round(
		1048560 / round(sqrt(round(sqrt(16711680 / float(modified_catch_rate))))),
	)

	var times: int = 0
	var success: bool = modified_catch_rate >= 255
	if modified_catch_rate < 255:
		while times < 4:
			if shake_check(shake_probability):
				times += 1
			else:
				break

	if times == 4:
		success = true

	var result: Dictionary = {
		"times": times,
		"success": success,
	}

	return result


func get_status_catch_bonus() -> float:
	if has_status_in_slot(StatusData.StatusSlot.MAIN):
		match get_status_in_slot(StatusData.StatusSlot.MAIN).status_id:
			"freeze", "sleep":
				return 2.0
			"paralyze", "poison", "burn":
				return 1.5
	return 1.0


func shake_check(shake_probablity: int) -> bool:
	var chance: int = randi_range(0, 65535)
	return chance >= shake_probablity


func hold_item(item: Item) -> bool:
	if held_item == null:
		held_item = item
		return true
	return false


func swap_items(item: Item) -> void:
	var temp: Item = held_item
	held_item = item
	Inventory.send_item_to_inventory.emit(temp)


func take_item() -> void:
	var temp = held_item
	held_item = null
	Inventory.send_item_to_inventory.emit(temp)
