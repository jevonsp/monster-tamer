class_name FxAction
extends Action

@export var fx_id: StringName = &""
@export var payload: Dictionary = { }


func _trigger_impl(ctx: ActionContext) -> Flow:
	@warning_ignore("redundant_await")
	await ctx.presenter.play_fx(fx_id, payload)
	return Flow.NEXT
