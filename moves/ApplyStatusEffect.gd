extends MoveEffect
class_name ApplyStatusEffect

@export var status_data: StatusData
@export var duration_override: int = -1

func apply(_actor: Monster, target: Monster, context: BattleContext, _move_name: String = "", _animation: PackedScene = null) -> void:
	var duration := duration_override if duration_override > 0 else status_data.default_duration
	var has_status: bool = false
	for status: StatusInstance in target.statuses:
		if status.data.status_name == status_data.status_name:
			has_status = true
	if not has_status:
		await target.add_status(status_data, duration, context)
