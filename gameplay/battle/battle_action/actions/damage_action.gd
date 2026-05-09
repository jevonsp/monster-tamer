class_name DamageAction
extends Action

@export var base_power: int = 30
@export var type: TypeChart.Type = TypeChart.Type.NONE
@export var damage_category: DamageCalculator.DamageCategory = DamageCalculator.DamageCategory.PHYSICAL
@export var attack_stat: DamageCalculator.AttackCategory = DamageCalculator.AttackCategory.PHYSICAL
@export var recoil_percent: float = 0.0
@export var target_self: bool = false
@export_range(0.0, 1.0, .001) var fraction_of_max_hp: float = 0.0


func _trigger_impl(ctx: ActionContext) -> Flow:
	var target: Monster = _resolve_target(ctx)
	if target == null:
		return Flow.NEXT

	var from_hp := target.current_hitpoints
	var weather: Weather = ctx.chassis.current_weather if ctx.chassis != null else null
	var pack: Dictionary = DamageCalculator.compute_damage_event(
		ctx.choice.actor,
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

	target.current_hitpoints = maxi(0, from_hp - dmg)

	var target_fainted := target.current_hitpoints <= 0
	if target_fainted:
		target.is_fainted = true

	ctx.data["last_hp_change"] = {
		"target": target,
		"from": from_hp,
		"to": target.current_hitpoints,
		"damage": dmg,
		"efficacy": efficacy,
		"critical": critical,
		"target_fainted": target_fainted,
	}

	return Flow.NEXT


func _resolve_target(ctx: ActionContext) -> Monster:
	if target_self:
		return ctx.choice.actor
	if ctx.choice.targets.is_empty():
		return null
	return ctx.choice.targets[0]
