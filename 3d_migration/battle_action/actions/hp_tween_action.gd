class_name HpTweenAction
extends Action


func _trigger_impl(ctx: ActionContext) -> Flow:
	if not ctx.data.has("last_hp_change"):
		return Flow.NEXT

	var hp_evt: Dictionary = ctx.data["last_hp_change"]
	@warning_ignore("redundant_await")
	await ctx.presenter.tween_hp(hp_evt["target"], hp_evt["from"], hp_evt["to"])

	return Flow.NEXT
