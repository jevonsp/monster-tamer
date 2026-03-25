class_name DamageEffect
extends MoveEffect

@export var type: TypeChart.Type
@export var base_power: int = 30
enum DamageType { PHYSICAL, SPECIAL }
@export var damage_type: DamageType = DamageType.PHYSICAL


func apply(
	actor: Monster, 
	target: Monster, 
	context: BattleContext, 
	move_name: String = "attack", 
	animation: PackedScene = null
) -> void:
	var efficacy := TypeChart.get_attacking_type_efficacy(type, target)
	var damage := calculate_damage(actor, target)
	
	var is_critical = calculate_critical(actor)
	damage = damage * 2 if is_critical else damage
	await context.show_move_used_text(actor, move_name, target)
	if animation != null:
		await context.play_move_animation(animation)
	context.play_hit_reaction(target)
	await target.take_damage(damage)

	var lines: Array[String] = [""]
	if is_critical:
		lines[0] += "A critical hit!\n"
	lines[0] += "It dealt %s damage.\n" % damage
	if efficacy > 1.0:
		lines[0] += "It's super effective!"
	elif efficacy < 1.0:
		lines[0] += "It's not very effective..."

	await context.show_move_result_text(lines)
	target.check_faint()


func _get_damage_stats(actor: Monster, target: Monster) -> Array:
	var atk_stat: Monster.Stat
	var def_stat: Monster.Stat

	match damage_type:
		DamageType.PHYSICAL:
			atk_stat = Monster.Stat.ATTACK
			def_stat = Monster.Stat.DEFENSE
		DamageType.SPECIAL:
			atk_stat = Monster.Stat.SPECIAL_ATTACK
			def_stat = Monster.Stat.SPECIAL_DEFENSE

	var attacking_stat = actor.get_stat(atk_stat) * actor.get_stat_stage_multi(atk_stat)
	var defending_stat = target.get_stat(def_stat) * target.get_stat_stage_multi(def_stat)
	var attacking_multi = actor.stat_stages_and_multis.stat_multipliers[atk_stat]
	var defending_multi = target.stat_stages_and_multis.stat_multipliers[def_stat]

	return [attacking_stat, defending_stat, attacking_multi, defending_multi]


func _get_item_boost(monster: Monster) -> Variant:
	if not monster.held_item or not monster.held_item.held_effect:
		return null
	if monster.held_item.held_effect.effect_type != HeldEffect.EffectType.TYPE_BOOST:
		return null

	match monster.held_item.held_effect.BoostType:
		HeldEffect.BoostType.PERCENTAGE:
			return monster.held_item.held_effect.get_percent_bonus()
		HeldEffect.BoostType.FLAT:
			return monster.held_item.held_effect.get_flat_bonus()

	return null


func calculate_damage(actor: Monster, target: Monster) -> int:
	var efficacy := TypeChart.get_attacking_type_efficacy(type, target)
	var stats := _get_damage_stats(actor, target)
	var attacking_stat: float = stats[0]
	var defending_stat: float = stats[1]
	var attacking_multi: float = stats[2]
	var defending_multi: float = stats[3]

	var stab_bonus := 1.5 if (actor.primary_type == type or actor.secondary_type == type) else 1.0
	var multi := efficacy * attacking_multi * defending_multi * stab_bonus

	var level_factor := ((2.0 * actor.level) / 5.0) + 2.0
	var damage := ((level_factor * base_power * (attacking_stat / defending_stat)) / 50.0 + 2.0) * multi

	var attacking_item_boost = _get_item_boost(actor)
	var defending_item_boost = _get_item_boost(target)

	if attacking_item_boost is int:
		damage += attacking_item_boost
	elif attacking_item_boost is float:
		damage *= attacking_item_boost

	if defending_item_boost is int:
		damage -= defending_item_boost
	elif defending_item_boost is float:
		damage /= defending_item_boost

	return int(ceil(damage))


func calculate_critical(actor: Monster) -> bool:
	var critical_chance = actor.get_stat_stage_multi(Monster.Stat.CRITICAL)
	if randf() <= critical_chance:
		return true
	return false
