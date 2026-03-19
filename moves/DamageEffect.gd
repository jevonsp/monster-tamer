extends MoveEffect
class_name DamageEffect

@export var type: TypeChart.Type
@export var base_power: int = 30
enum DamageType { PHYSICAL, SPECIAL }
@export var damage_type: DamageType = DamageType.PHYSICAL


func apply(actor: Monster, target: Monster, context: BattleContext, move_name: String = "attack", animation: PackedScene = null) -> void:
	var efficacy := TypeChart.get_attacking_type_efficacy(type, target.type)
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
	await target.check_faint()


func calculate_damage(actor: Monster, target: Monster) -> int:
	var efficacy := TypeChart.get_attacking_type_efficacy(type, target.type)
	var attacking_stat: float
	var attacking_stat_stage_multi: float
	var attacking_multi: float
	var defending_stat: float
	var defending_stat_stage_multi: float
	var defending_multi: float
	match damage_type:
		DamageType.PHYSICAL:
			attacking_stat_stage_multi = actor.get_stat_stage_multi(Monster.Stat.ATTACK)
			attacking_stat = actor.attack * attacking_stat_stage_multi
			attacking_multi = actor.stat_multis.stat_multipliers[Monster.Stat.ATTACK]
			
			defending_stat_stage_multi = target.get_stat_stage_multi(Monster.Stat.DEFENSE)
			defending_stat = target.defense * defending_stat_stage_multi
			defending_multi = target.stat_multis.stat_multipliers[Monster.Stat.DEFENSE]
		DamageType.SPECIAL:
			attacking_stat_stage_multi = actor.get_stat_stage_multi(Monster.Stat.SPECIAL_ATTACK)
			attacking_stat = actor.special_attack * attacking_stat_stage_multi
			attacking_multi = actor.stat_multis.stat_multipliers[Monster.Stat.SPECIAL_ATTACK]
			
			defending_stat_stage_multi = target.get_stat_stage_multi(Monster.Stat.SPECIAL_DEFENSE)
			defending_stat = target.special_defense * defending_stat_stage_multi
			defending_multi = target.stat_multis.stat_multipliers[Monster.Stat.SPECIAL_DEFENSE]
	
	var level_based_damage = (((2 * actor.level) / 5.0) + 2)
	var scaling_based_damage = (base_power * (attacking_stat / defending_stat))
	var stab_bonus = 1.5 if actor.type == type else 1.0
	var multi = efficacy * attacking_multi * defending_multi * stab_bonus
	var final_damage = (((level_based_damage * scaling_based_damage) / 50.0) + 2) * multi
	
	return int(ceil(final_damage))


func calculate_critical(actor: Monster) -> bool:
	var critical_chance = actor.get_stat_stage_multi(Monster.Stat.CRITICAL)
	if randf() <= critical_chance:
		return true
	return false
