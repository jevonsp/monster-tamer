class_name WeatherPersistAction
extends Action

@export_range(0.0, 1.0, 0.001) var fraction_of_max_hp: float = 0.0625


static func _is_protected_by_weather_boost(monster: Monster, weather: Weather) -> bool:
	for bt: TypeChart.Type in weather.boosted_types:
		if monster.primary_type == bt:
			return true
		if monster.secondary_type != TypeChart.Type.NONE and monster.secondary_type == bt:
			return true
	return false


func _trigger_impl(ctx: ActionContext) -> Flow:
	if ctx.chassis == null:
		return Flow.NEXT
	var weather: Weather = ctx.chassis.current_weather
	if weather == null:
		return Flow.NEXT

	var hp_events: Array[Dictionary] = []
	var faint_after: Array[Monster] = []

	for target: Monster in ctx.chassis.get_active_battle_monsters():
		if _is_protected_by_weather_boost(target, weather):
			continue

		var from_hp := target.current_hitpoints
		var pack: Dictionary = DamageCalculator.compute_damage_event(
			null,
			target,
			0,
			TypeChart.Type.NONE,
			DamageCalculator.DamageCategory.PHYSICAL,
			DamageCalculator.AttackCategory.PHYSICAL,
			fraction_of_max_hp,
			0.0,
			null,
		)
		var dmg: int = pack["damage"]
		target.current_hitpoints = maxi(0, from_hp - dmg)
		var target_fainted := target.current_hitpoints <= 0
		if target_fainted:
			target.is_fainted = true

		hp_events.append(
			{
				"target": target,
				"from": from_hp,
				"to": target.current_hitpoints,
			},
		)
		if target_fainted:
			faint_after.append(target)

	if not hp_events.is_empty():
		var tween_ctx := ctx.fork()
		@warning_ignore("redundant_await")
		await ctx.presenter.tween_hp_simultaneous(tween_ctx, hp_events)

	for f: Monster in faint_after:
		var fx_ctx := ctx.fork()
		@warning_ignore("redundant_await")
		await ctx.presenter.play_fx(fx_ctx, &"faint", { "target": f })

	var label: String = weather.display_name
	if label.is_empty():
		label = "The weather"
	var msg_ctx := ctx.fork()
	@warning_ignore("redundant_await")
	await ctx.presenter.show_text(msg_ctx, ["%s damaged the field!" % label], true)

	return Flow.NEXT
