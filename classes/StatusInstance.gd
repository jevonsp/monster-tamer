extends RefCounted
class_name StatusInstance
## Runtime instance of a status on a monster (duration, owner). Delegates hooks to StatusData.

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


func on_apply(context: BattleContext) -> void:
	if data:
		await data.on_apply(owner, context)


func on_turn_start(context: BattleContext) -> void:
	if data:
		await data.on_turn_start(owner, context)


func on_remove(context: BattleContext) -> void:
	if data:
		await data.on_remove(owner, context)
