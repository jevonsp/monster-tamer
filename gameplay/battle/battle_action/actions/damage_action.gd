class_name DamageAction
extends Action

enum DamageCategory { PHYSICAL, SPECIAL }
enum AttackCategory { PHYSICAL, SPECIAL }

@export var base_power: int = 30
@export var type: TypeChart.Type = TypeChart.Type.NONE
@export var damage_category: DamageCategory = DamageCategory.PHYSICAL
@export var attack_stat: AttackCategory = AttackCategory.PHYSICAL
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


func _calc_damage(attacker: Monster, target: Monster) -> int:
	if attacker == null:
		return 0

	var attack := _get_effective_attacking_stat(attacker, attack_stat)
	var defense := _get_effective_defending_stat(target, damage_category)

	var stab := _get_stab_bonus(attacker)
	var final := _get_final_damage(attacker, target, attack, defense) * stab

	return int(final)


func _get_effective_attacking_stat(attacker: Monster, category: AttackCategory) -> int:
	if category == AttackCategory.PHYSICAL:
		return round(attacker.get_effective_stat(Monster.Stat.ATTACK))
	return round(attacker.get_effective_stat(Monster.Stat.SPECIAL_ATTACK))


func _get_effective_defending_stat(defender: Monster, category: DamageCategory) -> int:
	if category == DamageCategory.PHYSICAL:
		return round(defender.get_effective_stat(Monster.Stat.DEFENSE))
	return round(defender.get_effective_stat(Monster.Stat.SPECIAL_DEFENSE))


func _get_stab_bonus(attacker: Monster) -> float:
	if attacker.secondary_type == TypeChart.Type.NONE:
		if attacker.primary_type == type:
			return 1.5
		return 1.0
	if attacker.primary_type == type or attacker.secondary_type == type:
		return 1.5
	return 1.0


func _get_final_damage(attacker: Monster, _defender: Monster, a_stat: int, d_stat: int) -> int:
	var level_factor := ((2.0 * attacker.level) / 5.0) + 2.0
	var stat_ratio := a_stat / float(d_stat)
	var damage := ((level_factor * base_power * stat_ratio) / 50.0) + 2.0

	return int(damage)


func _calc_critical(_attacker: Monster, _target: Monster) -> bool:
	return false


func _calc_recoil(damage: int) -> int:
	return int(damage * recoil_percent)
