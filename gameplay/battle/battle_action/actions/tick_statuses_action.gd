class_name TickStatusesAction
extends Action

## Decrements turns_remaining on the currently acting status (set by
## BattleChassis._resolve_statuses_for_phase via ctx.data["acting_status"]) and,
## when it expires, removes it from the actor and runs its on_expire ActionList.
func _trigger_impl(ctx: ActionContext) -> Flow:
	var instance: StatusInstance = ctx.data.get("acting_status", null)
	if instance == null or instance.data == null:
		return Flow.NEXT

	if instance.turns_remaining < 0:
		return Flow.NEXT

	instance.turns_remaining -= 1
	if instance.turns_remaining > 0:
		return Flow.NEXT

	var actor: Monster = ctx.choice.actor
	if actor != null and instance.data.id != &"":
		actor.remove_status(instance.data.id)

	if instance.data.on_expire != null:
		var fork := ctx.fork()
		fork.data["acting_status"] = instance
		@warning_ignore("redundant_await")
		await instance.data.on_expire.run(fork)
	return Flow.NEXT
