class_name HpTweenAction
extends Action


func _trigger_impl(ctx: ActionContext) -> Flow:
	if not ctx.data.has("last_hp_change"):
		return Flow.NEXT

	var hp_evt: Dictionary = ctx.data["last_hp_change"]
	var new_ctx = ctx.fork()
	@warning_ignore("redundant_await")
	await ctx.presenter.tween_hp(new_ctx, hp_evt["target"], hp_evt["from"], hp_evt["to"])

	if hp_evt["target_fainted"]:
		@warning_ignore("redundant_await")
		await ctx.presenter.play_fx(new_ctx, "faint", {"target": hp_evt["target"]})

	return Flow.NEXT
