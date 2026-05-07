class_name FxAction
extends Action

## When set, instantiated under the target's TextureRect (MoveAnimation
## pattern). Takes precedence over fx_id.
@export var fx_scene: PackedScene = null
@export var fx_id: StringName = &""
@export var payload: Dictionary = { }
## When true, target is ctx.choice.actor instead of the opposing actor. Used
## by self-targeted FX (e.g. burn tick on the burned mon).
@export var target_self: bool = false


func _trigger_impl(ctx: ActionContext) -> Flow:
	var target: Monster = _resolve_target(ctx)
	if fx_scene != null:
		var scene_ctx := ctx.fork()
		@warning_ignore("redundant_await")
		await ctx.presenter.play_fx_scene(scene_ctx, fx_scene, target)
		return Flow.NEXT
	if fx_id != &"":
		payload["target"] = target
		var legacy_ctx := ctx.fork()
		@warning_ignore("redundant_await")
		await ctx.presenter.play_fx(legacy_ctx, fx_id, payload)
	return Flow.NEXT


func _resolve_target(ctx: ActionContext) -> Monster:
	if target_self:
		return ctx.choice.actor
	if ctx.chassis.is_player_actor(ctx.choice.actor):
		return Battle.resolve_enemy_actor()
	return Battle.resolve_player_actor()
