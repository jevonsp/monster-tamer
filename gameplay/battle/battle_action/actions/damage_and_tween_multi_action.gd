class_name DamageAndTweenMultiAction
extends Action

@export var base_power: int = 30
@export var type: TypeChart.Type = TypeChart.Type.NONE
@export var damage_category: DamageCalculator.DamageCategory = DamageCalculator.DamageCategory.PHYSICAL
@export var attack_stat: DamageCalculator.AttackCategory = DamageCalculator.AttackCategory.PHYSICAL
@export_range(0.0, 1.0, .001) var fraction_of_max_hp: float = 0.0
@export var recoil_percent: float = 0.0


func _trigger_impl(ctx: ActionContext) -> Flow:
	var attacker: Monster = ctx.choice.actor
	var targets: Array[Monster] = _resolve_targets(ctx)
	if targets.is_empty():
		return Flow.NEXT

	for target in targets:
		if target == null:
			continue

		var weather: Weather = ctx.chassis.current_weather if ctx.chassis != null else null
		var hp_evt := _apply_damage(attacker, target, weather)
		var ctx_2 := ctx.fork()
		@warning_ignore("redundant_await")
		await ctx.presenter.tween_hp(ctx_2, hp_evt["target"], hp_evt["from"], hp_evt["to"])

		if hp_evt["target_fainted"]:
			@warning_ignore("redundant_await")
			await ctx.presenter.play_fx(ctx_2, "faint", { "target": hp_evt["target"] })

		var recoil_amt: int = hp_evt.get("recoil", 0)
		if recoil_amt > 0 and attacker != null:
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
				await ctx.presenter.play_fx(recoil_ctx, "faint", { "target": attacker })

	return Flow.NEXT


func _resolve_targets(ctx: ActionContext) -> Array[Monster]:
	var result: Array[Monster] = []
	for target in ctx.choice.targets:
		var m: Monster = target
		if m != null:
			result.append(m)
	return result


func _apply_damage(attacker: Monster, target: Monster, weather: Weather) -> Dictionary:
	var from_hp := target.current_hitpoints
	var pack: Dictionary = DamageCalculator.compute_damage_event(
		attacker,
		target,
		base_power,
		type,
		damage_category,
		attack_stat,
		fraction_of_max_hp,
		recoil_percent,
		weather,
	)
	var dmg: int = pack["damage"]
	var critical: bool = pack["critical"]
	var efficacy: float = pack["efficacy"]
	var recoil: int = pack["recoil"]

	target.current_hitpoints = maxi(0, from_hp - dmg)

	var target_fainted := target.current_hitpoints <= 0
	if target_fainted:
		target.is_fainted = true

	return {
		"target": target,
		"from": from_hp,
		"to": target.current_hitpoints,
		"damage": dmg,
		"efficacy": efficacy,
		"critical": critical,
		"target_fainted": target_fainted,
		"recoil": recoil,
	}
