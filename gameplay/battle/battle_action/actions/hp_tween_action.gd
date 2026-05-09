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

	var recoil_amt: int = hp_evt.get("recoil", 0)
	if recoil_amt > 0:
		var attacker: Monster = ctx.choice.actor
		if attacker != null:
			var from_a := attacker.current_hitpoints
			attacker.current_hitpoints = maxi(0, from_a - recoil_amt)
			var attacker_fainted := attacker.current_hitpoints <= 0
			if attacker_fainted:
				attacker.is_fainted = true
			var recoil_ctx := ctx.fork()
			@warning_ignore("redundant_await")
			await ctx.presenter.tween_hp(recoil_ctx, attacker, from_a, attacker.current_hitpoints)
			if attacker_fainted:
				@warning_ignore("redundant_await")
				await ctx.presenter.play_fx(recoil_ctx, "faint", {"target": attacker})

	return Flow.NEXT
