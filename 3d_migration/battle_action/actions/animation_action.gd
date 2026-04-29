class_name AnimationAction
extends Action


func _trigger_impl(ctx: ActionContext) -> Flow:
	await ctx.presenter.play_move_animation(ctx.choice)
	return Flow.NEXT
