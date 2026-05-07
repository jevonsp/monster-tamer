class_name DamageAction
extends Action

enum DamageCategory { PHYSICAL, SPECIAL }

@export var base_power: int = 30
@export var type: TypeChart.Type = TypeChart.Type.NONE
@export var category: DamageCategory = DamageCategory.PHYSICAL
@export var recoil_percent: float = 0.0
## When true, the action damages ctx.choice.actor instead of the first target.
## Used by self-damage status ticks (e.g. burn, poison).
@export var target_self: bool = false
## When > 0, damage is `target.max_hitpoints * fraction_of_max_hp` instead of
## the base_power formula. Bypasses attacker stats and crits.
@export_range(0.0, 1.0, .001) var fraction_of_max_hp: float = 0.0


func _trigger_impl(ctx: ActionContext) -> Flow:
	var target: Monster = _resolve_target(ctx)
	if target == null:
		return Flow.NEXT

	var from_hp := target.current_hitpoints
	var dmg: int = 0
	var critical: bool = false
	var efficacy: float = 1.0

	if fraction_of_max_hp > 0.0:
		dmg = maxi(1, int(round(float(target.max_hitpoints) * fraction_of_max_hp)))
	else:
		dmg = _calc_damage(ctx.choice.actor, target)
		critical = _calc_critical(ctx.choice.actor, target)
		if critical:
			dmg *= 2
		efficacy = _calc_efficacy(ctx.choice.actor, target)
		dmg = round(dmg * efficacy)

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


func _calc_efficacy(_attacker: Monster, _target: Monster) -> float:
	return 1.0


func _calc_damage(attacker: Monster, _target: Monster) -> int:
	if attacker == null:
		return base_power
	var attack_stat: float = float(attacker.attack)
	match category:
		DamageCategory.PHYSICAL:
			attack_stat = attacker.get_effective_stat(Monster.Stat.ATTACK)
		DamageCategory.SPECIAL:
			attack_stat = attacker.get_effective_stat(Monster.Stat.SPECIAL_ATTACK)
	# Placeholder formula until full damage math is implemented; routes attack
	# through get_effective_stat so passive status multipliers (e.g. burn) apply.
	var base_attack: float = max(1.0, float(attacker.attack))
	var ratio: float = attack_stat / base_attack
	return int(round(float(base_power) * ratio))


func _calc_critical(_attacker: Monster, _target: Monster) -> bool:
	return false


func _calc_recoil() -> int:
	return 0
