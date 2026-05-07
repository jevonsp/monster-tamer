class_name FxAction
extends Action

@export var fx_id: StringName = &""
@export var payload: Dictionary = { }
## When true, payload["target"] is set to ctx.choice.actor instead of the
## opposing actor. Used by self-targeted FX (e.g. burn tick on the burned mon).
@export var target_self: bool = false


func _trigger_impl(ctx: ActionContext) -> Flow:
	if target_self:
		payload["target"] = ctx.choice.actor
	elif ctx.chassis.is_player_actor(ctx.choice.actor):
		payload["target"] = Battle.resolve_enemy_actor()
	else:
		payload["target"] = Battle.resolve_player_actor()
	var new_ctx = ctx.fork()
	@warning_ignore("redundant_await")
	await ctx.presenter.play_fx(new_ctx, fx_id, payload)
	return Flow.NEXT
