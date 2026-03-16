extends RefCounted
class_name StatusInstance

var data: StatusData
var remaining_turns: int
var owner: Monster


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
	return remaining_turns <= 0


func tick_duration() -> void:
	if remaining_turns > 0:
		remaining_turns -= 1


func expire() -> void:
	remaining_turns = 0


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
