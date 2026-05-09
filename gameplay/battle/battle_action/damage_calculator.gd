class_name DamageCalculator
extends RefCounted

enum DamageCategory { PHYSICAL, SPECIAL }
enum AttackCategory { PHYSICAL, SPECIAL }


static func compute_damage_event(
		attacker: Monster,
		target: Monster,
		base_power: int,
		move_type: TypeChart.Type,
		damage_category: DamageCategory,
		attack_stat_cat: AttackCategory,
		fraction_of_max_hp: float,
		recoil_percent: float,
		weather: Weather = null,
) -> Dictionary:
	if fraction_of_max_hp > 0.0:
		var frac_dmg := maxi(1, int(round(float(target.max_hitpoints) * fraction_of_max_hp)))
		return {
			"damage": frac_dmg,
			"critical": false,
			"efficacy": 1.0,
			"recoil": _recoil_from_dealt(frac_dmg, recoil_percent),
		}
	var efficacy: float = _calc_efficacy(move_type, target)
	var dmg: int = _calc_damage(
		attacker,
		target,
		base_power,
		move_type,
		damage_category,
		attack_stat_cat,
		weather,
	)
	var critical: bool = _calc_critical(attacker)
	if critical:
		dmg *= 2
	dmg = int(round(float(dmg) * efficacy))

	return {
		"damage": dmg,
		"critical": critical,
		"efficacy": efficacy,
		"recoil": _recoil_from_dealt(dmg, recoil_percent),
	}


static func _calc_damage(
		attacker: Monster,
		target: Monster,
		base_power: int,
		move_type: TypeChart.Type,
		damage_category: DamageCategory,
		attack_stat_cat: AttackCategory,
		weather: Weather = null,
) -> int:
	if attacker == null:
		return 0

	var attack := _get_effective_attacking_stat(attacker, attack_stat_cat)
	var defense := _get_effective_defending_stat(target, damage_category)
	var stab := _get_stab_bonus(attacker, move_type)
	var weather_bonus := _calc_weather(move_type, weather)

	var final := float(
		_get_final_damage(
			attacker,
			base_power,
			attack,
			defense,
		),
	) * stab * weather_bonus

	return int(final)


static func _get_effective_attacking_stat(attacker: Monster, category: AttackCategory) -> int:
	if category == AttackCategory.PHYSICAL:
		return int(round(attacker.get_effective_stat(Monster.Stat.ATTACK)))
	return int(round(attacker.get_effective_stat(Monster.Stat.SPECIAL_ATTACK)))


static func _get_effective_defending_stat(defender: Monster, category: DamageCategory) -> int:
	if category == DamageCategory.PHYSICAL:
		return int(round(defender.get_effective_stat(Monster.Stat.DEFENSE)))
	return int(round(defender.get_effective_stat(Monster.Stat.SPECIAL_DEFENSE)))


static func _get_stab_bonus(attacker: Monster, move_type: TypeChart.Type) -> float:
	return TypeChart.get_stab_bonus(move_type, attacker)


static func _get_final_damage(attacker: Monster, base_power: int, a_stat: int, d_stat: int) -> int:
	var level_factor := ((2.0 * attacker.level) / 5.0) + 2.0
	var stat_ratio := a_stat / float(d_stat)
	var damage := ((level_factor * base_power * stat_ratio) / 50.0) + 2.0

	return int(damage)


static func _calc_critical(attacker: Monster) -> bool:
	var crit_stage: int = int(attacker.stat_stages_and_multis.stat_stages[Monster.Stat.CRITICAL])
	var crit_chance: float = MonsterStatMultipliers.critical_stage_multi[crit_stage]
	return crit_chance > randf()


static func _calc_efficacy(move_type: TypeChart.Type, target: Monster) -> float:
	return TypeChart.get_attacking_type_efficacy(move_type, target)


static func _calc_weather(move_type: TypeChart.Type, weather: Weather = null) -> float:
	if not weather:
		return 1.0
	if weather.is_type_boosted(move_type):
		return 1.5
	if weather.is_type_lowered(move_type):
		return .75
	return 1.0


static func _recoil_from_dealt(dealt: int, recoil_percent: float) -> int:
	if recoil_percent <= 0.0:
		return 0
	return int(round(float(dealt) * recoil_percent))
