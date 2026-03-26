class_name ApplyStatusEffect
extends MoveEffect

@export var status_data: StatusData
@export var application_chance: float = 1.0
@export var duration_override: int = -1


func apply(
		_actor: Monster,
		target: Monster,
		context: BattleContext,
		_move_name: String = "",
		_animation: PackedScene = null,
) -> void:
	var duration := duration_override if duration_override > 0 else status_data.default_duration
	if not target.is_able_to_fight:
		return

	var is_successful: bool = randf() <= application_chance

	if not is_successful:
		return

	var result := await target.add_status(status_data, duration, context)
	match result:
		Monster.StatusApplyResult.APPLIED:
			var applied_text: Array[String] = [
				"%s was afflicted with %s" % [target.name, status_data.status_name],
			]
			await context.show_text(applied_text)
		Monster.StatusApplyResult.REFRESHED:
			var refreshed_text: Array[String] = [
				"%s's %s duration was refreshed." % [target.name, status_data.status_name],
			]
			await context.show_text(refreshed_text)
		Monster.StatusApplyResult.BLOCKED_DUPLICATE, Monster.StatusApplyResult.BLOCKED_SLOT_CONFLICT:
			var blocked_text: Array[String] = ["But it failed!"]
			await context.show_text(blocked_text)
