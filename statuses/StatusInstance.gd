extends RefCounted
class_name StatusInstance

var data: StatusData
var remaining_turns: int
var owner: Monster
var blocks_action_this_turn: bool = false
var runtime_data: Dictionary = {}


func _init(p_data: StatusData = null, p_owner: Monster = null, duration: int = -1) -> void:
	data = p_data
	owner = p_owner
	if duration > 0:
		remaining_turns = duration
	elif data:
		remaining_turns = data.default_duration
	else:
		remaining_turns = 0


func is_expired() -> bool:
	return remaining_turns == 0


func tick_duration() -> void:
	if remaining_turns > 0:
		remaining_turns -= 1


func expire() -> void:
	remaining_turns = 0


func reset_turn_state() -> void:
	blocks_action_this_turn = false
	runtime_data.clear()


func on_apply(context: BattleContext) -> void:
	if data:
		@warning_ignore("redundant_await")
		await data.on_apply(self, owner, context)


func on_turn_start(context: BattleContext) -> void:
	if data:
		@warning_ignore("redundant_await")
		await data.on_turn_start(self, owner, context)


func on_turn_end(context: BattleContext) -> void:
	if data:
		@warning_ignore("redundant_await")
		await data.on_turn_end(self, owner, context)


func on_remove(context: BattleContext) -> void:
	if data:
		@warning_ignore("redundant_await")
		await data.on_remove(self, owner, context)


func modify_effective_stat(stat: Monster.Stat, value: float) -> float:
	if data:
		return data.modify_effective_stat(self, owner, stat, value)
	return value


func can_attempt_action(context: BattleContext) -> bool:
	if data:
		return data.can_attempt_action(self, owner, context)
	return true


func get_action_block_text() -> Array[String]:
	if data:
		return data.get_action_block_text(self, owner)
	return []


func has_action_override(context: BattleContext, chosen_action) -> bool:
	if data:
		return data.has_action_override(self, owner, context, chosen_action)
	return false


func execute_action_override(target: Monster, context: BattleContext, chosen_action) -> void:
	if data:
		@warning_ignore("redundant_await")
		await data.execute_action_override(self, owner, target, context, chosen_action)
