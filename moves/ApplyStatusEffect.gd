extends MoveEffect
class_name ApplyStatusEffect

@export var status_data: StatusData
@export var duration_override: int = -1

func apply(_actor: Monster, target: Monster, context: BattleContext, _move_name: String = "", _animation: PackedScene = null) -> void:
	var duration := duration_override if duration_override > 0 else status_data.default_duration
	var has_status := target.has_status_id(status_data.get_identifier())
	if not has_status and target.is_able_to_fight:
		await target.add_status(status_data, duration, context)
		var text_array: Array[String] = ["%s was afflicted with %s" % [target.name, status_data.status_name]]
		await context.show_text(text_array)
