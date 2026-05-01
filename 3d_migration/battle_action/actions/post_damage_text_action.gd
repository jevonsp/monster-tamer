class_name PostDamageTextAction
extends Action


func _trigger_impl(ctx: ActionContext) -> Flow:
	var data = ctx.data
	var last_hp_change: Dictionary = data["last_hp_change"]
	var actor: Monster = ctx.choice.actor
	var target: Monster = last_hp_change["target"]
	var target_fainted = last_hp_change["target_fainted"]
	var damage: int = last_hp_change["damage"]
	var _critical = last_hp_change["critical"]
	var _efficacy = last_hp_change["efficacy"]

	var t: String = ""
	if ctx.chassis.is_enemy_actor(target):
		if target_fainted:
			t = "Foe %s fainted!" % target.name
		else:
			t = "Enemy %s did %d damage!" % [actor.name, damage]
	else:
		if target_fainted:
			t = "Oh no! %s fainted!" % target.name
		else:
			t = "%s did %d damage!" % [actor.name, damage]

	var new_ctx = ctx.fork()
	@warning_ignore("redundant_await")
	await ctx.presenter.show_text(new_ctx, [t])

	return Flow.NEXT
