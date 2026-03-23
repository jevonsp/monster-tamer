class_name StatusData
extends Resource

enum StatusSlot {
	MAIN,
	SEPARATE
}

@export var status_id: String = ""
@export var status_name: String = ""
@export var default_duration: int = 3
@export var status_slot: StatusSlot = StatusSlot.MAIN


func on_apply(_instance: StatusInstance, _owner: Monster, _context: BattleContext) -> void:
	pass


func on_turn_start(_instance: StatusInstance, _owner: Monster, _context: BattleContext) -> void:
	pass


func on_turn_end(_instance: StatusInstance, _owner: Monster, _context: BattleContext) -> void:
	pass


func on_remove(_instance: StatusInstance, _owner: Monster, _context: BattleContext) -> void:
	pass


func modify_effective_stat(
	_instance: StatusInstance,
	_owner: Monster,
	_stat: Monster.Stat,
	value: float
) -> float:
	return value


func can_attempt_action(
	_instance: StatusInstance,
	_owner: Monster,
	_context: BattleContext
) -> bool:
	return true


func get_action_block_text(_instance: StatusInstance, _owner: Monster) -> Array[String]:
	return []


func get_identifier() -> String:
	if not status_id.is_empty():
		return status_id
	return status_name


func has_action_override(
	_instance: StatusInstance,
	_owner: Monster,
	_context: BattleContext,
	_chosen_action
) -> bool:
	return false


func execute_action_override(
	_instance: StatusInstance,
	_owner: Monster,
	_target: Monster,
	_context: BattleContext,
	_chosen_action
) -> void:
	pass
