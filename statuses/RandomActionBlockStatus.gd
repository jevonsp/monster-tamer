extends StatusData
class_name RandomActionBlockStatus

@export_range(0.0, 1.0, 0.01) var block_chance: float = 0.25
@export_multiline var action_block_message: String = "%s is fully paralyzed!"


func on_turn_start(instance: StatusInstance, _owner: Monster, _context: BattleContext) -> void:
	var chance := randf()
	instance.blocks_action_this_turn = chance < block_chance
	instance.runtime_data["action_block_reason"] = "random"


func can_attempt_action(
	instance: StatusInstance,
	_owner: Monster,
	_context: BattleContext
) -> bool:
	return not instance.blocks_action_this_turn


func get_action_block_text(instance: StatusInstance, owner: Monster) -> Array[String]:
	if not instance.blocks_action_this_turn:
		return []
	return [action_block_message % owner.name]
