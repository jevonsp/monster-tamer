class_name ApplyStatusAction
extends Action

@export var status_data: StatusData = null
@export var target_self: bool = false
@export_range(0.0, 1.0) var apply_chance: float = 1.0


func _trigger_impl(ctx: ActionContext) -> Flow:
	if status_data == null:
		return Flow.NEXT

	var target: Monster = _resolve_target(ctx)
	if target == null or target.is_fainted:
		return Flow.NEXT

	if apply_chance < 1.0 and randf() > apply_chance:
		return Flow.NEXT

	var instance: StatusInstance = StatusInstance.from_data(status_data, ctx.choice.actor)
	var applied: bool = target.add_status(instance)
	if applied and status_data.on_apply != null:
		var fork := ctx.fork()
		fork.data["acting_status"] = instance
		@warning_ignore("redundant_await")
		await status_data.on_apply.run(fork)
	return Flow.NEXT


func _resolve_target(ctx: ActionContext) -> Monster:
	if target_self:
		return ctx.choice.actor
	if ctx.choice.targets.is_empty():
		return null
	return ctx.choice.targets[0]
