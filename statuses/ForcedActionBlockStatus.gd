class_name ForcedActionBlockStatus
extends StatusData

@export_range(0.0, 1.0, 0.01) var remove_chance: float = 0.0
@export_multiline var action_block_message: String = "%s cannot move!"


func on_turn_start(instance: StatusInstance, _owner: Monster, _context: BattleContext) -> void:
	if remove_chance > 0.0 and randf() < remove_chance:
		instance.expire()
		instance.blocks_action_this_turn = false
		return
	instance.blocks_action_this_turn = true
	instance.runtime_data["action_block_reason"] = "forced"


func can_attempt_action(
		instance: StatusInstance,
		_owner: Monster,
		_context: BattleContext,
) -> bool:
	return not instance.blocks_action_this_turn


func get_action_block_text(instance: StatusInstance, owner: Monster) -> Array[String]:
	if not instance.blocks_action_this_turn:
		return []
	return [action_block_message % owner.name]
