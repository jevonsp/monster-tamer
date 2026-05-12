class_name AttemptCatchAction
extends Action

var catch_rate: float = 0.75


func _trigger_impl(ctx: ActionContext) -> Flow:
	var target: Monster = _resolve_target(ctx)
	if target == null:
		return Flow.NEXT

	if ctx.chassis.is_trainer_battle:
		var text_action = TextAction.new()
		text_action.is_autocomplete = true
		text_action.text = "You cant catch other trainer's monsters!"
		var text_ctx = ctx.fork()
		# gdlint-ignore-next-line
		await text_action._trigger_impl(text_ctx)
		return Flow.STOP

	var pack = CaptureHelper.compute_capture_event(ctx.choice.actor, target, catch_rate)
	var times = pack.get("times")
	var success = pack.get("success")
	if times:
		var throw_fx = FxAction.new()
		throw_fx.fx_id = &"throw"
		var potential_item = ctx.choice.action_or_list
		if potential_item and potential_item is Item:
			throw_fx.payload["item"] = potential_item
		var fx_ctx = ctx.fork()
		# gdlint-ignore-next-line
		await throw_fx._trigger_impl(fx_ctx)
		var wiggle_fx = FxAction.new()
		wiggle_fx.fx_id = &"times"
		wiggle_fx.payload["times"] = times

	if success:
		PlayerContext3D.party_handler.add(target)
		target.is_captured = true
		var text_action = TextAction.new()
		text_action.needs_formatting = true
		text_action.text = "Lets go! The wild {target} was caught"
		var text_ctx = ctx.fork()
		# gdlint-ignore-next-line
		await text_action._trigger_impl(text_ctx)
		return Flow.STOP

	return Flow.NEXT


func _resolve_target(ctx: ActionContext) -> Monster:
	if ctx.choice.targets.is_empty():
		return null
	return ctx.choice.targets[0]
