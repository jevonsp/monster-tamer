class_name AnimationAction
extends Action


func _trigger_impl(ctx: ActionContext) -> Flow:
	var new_ctx = ctx.fork()
	@warning_ignore("redundant_await")
	await ctx.presenter.play_move_animation(new_ctx, ctx.choice)
	return Flow.NEXT
