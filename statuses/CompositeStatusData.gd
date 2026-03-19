extends StatusData
class_name CompositeStatusData

@export var child_statuses: Array[StatusData] = []


func on_apply(instance: StatusInstance, owner: Monster, context: BattleContext) -> void:
	for child in child_statuses:
		if child != null:
			await child.on_apply(instance, owner, context)


func on_turn_start(instance: StatusInstance, owner: Monster, context: BattleContext) -> void:
	for child in child_statuses:
		if child != null:
			await child.on_turn_start(instance, owner, context)


func on_turn_end(instance: StatusInstance, owner: Monster, context: BattleContext) -> void:
	for child in child_statuses:
		if child != null:
			await child.on_turn_end(instance, owner, context)


func on_remove(instance: StatusInstance, owner: Monster, context: BattleContext) -> void:
	for child in child_statuses:
		if child != null:
			await child.on_remove(instance, owner, context)


func modify_effective_stat(
	instance: StatusInstance,
	owner: Monster,
	stat: Monster.Stat,
	value: float
) -> float:
	var modified_value := value
	for child in child_statuses:
		if child != null:
			modified_value = child.modify_effective_stat(instance, owner, stat, modified_value)
	return modified_value


func can_attempt_action(
	instance: StatusInstance,
	owner: Monster,
	context: BattleContext
) -> bool:
	for child in child_statuses:
		if child != null and not child.can_attempt_action(instance, owner, context):
			return false
	return true


func get_action_block_text(instance: StatusInstance, owner: Monster) -> Array[String]:
	for child in child_statuses:
		if child == null:
			continue
		var text := child.get_action_block_text(instance, owner)
		if not text.is_empty():
			return text
	return []
