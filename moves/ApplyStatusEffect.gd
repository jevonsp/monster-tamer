extends MoveEffect
class_name ApplyStatusEffect

@export var status_data: StatusData
@export var duration_override: int = -1

func apply(_actor: Monster, target: Monster, context: BattleContext, _move_name: String = "", _animation: PackedScene = null) -> void:
	var duration := duration_override if duration_override > 0 else status_data.default_duration
	await target.add_status(status_data, duration, context)
