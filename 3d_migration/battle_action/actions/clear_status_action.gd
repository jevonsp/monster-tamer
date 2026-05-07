class_name ClearStatusAction
extends Action

@export var status_id: StringName = &""
@export var target_self: bool = false


func _trigger_impl(ctx: ActionContext) -> Flow:
	if status_id == &"":
		return Flow.NEXT

	var target: Monster = _resolve_target(ctx)
	if target == null:
		return Flow.NEXT

	var existing: StatusInstance = target.get_status_by_id(status_id)
	if existing == null:
		return Flow.NEXT

	target.remove_status(status_id)
	if existing.data != null and existing.data.on_expire != null:
		var fork := ctx.fork()
		fork.data["acting_status"] = existing
		@warning_ignore("redundant_await")
		await existing.data.on_expire.run(fork)
	return Flow.NEXT


func _resolve_target(ctx: ActionContext) -> Monster:
	if target_self:
		return ctx.choice.actor
	if ctx.choice.targets.is_empty():
		return null
	return ctx.choice.targets[0]
