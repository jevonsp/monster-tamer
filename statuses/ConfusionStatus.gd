extends StatusData
class_name ConfusionStatus

@export_range(0.0, 1.0, 0.01) var self_hit_chance: float = 0.5
@export var self_hit_power: int = 30
@export_multiline var confusion_message: String = "%s is confused!"
@export_multiline var self_hit_message: String = "%s hurt itself in its confusion!"


func on_turn_start(instance: StatusInstance, _owner: Monster, _context: BattleContext) -> void:
	instance.runtime_data["confusion_self_hit"] = randf() < self_hit_chance


func has_action_override(
	instance: StatusInstance,
	_owner: Monster,
	_context: BattleContext,
	chosen_action
) -> bool:
	if not (chosen_action is Move):
		return false
	return instance.runtime_data.get("confusion_self_hit", false)


func execute_action_override(
	instance: StatusInstance,
	owner: Monster,
	_target: Monster,
	context: BattleContext,
	_chosen_action
) -> void:
	await context.show_text([confusion_message % owner.name])
	await context.show_text([self_hit_message % owner.name])

	var damage := _calculate_self_hit_damage(owner)
	context.play_hit_reaction(owner)
	await owner.take_damage(damage)
	await context.show_move_result_text(["It dealt %s damage." % damage])
	owner.check_faint()
	instance.runtime_data["confusion_self_hit"] = false


func _calculate_self_hit_damage(owner: Monster) -> int:
	var efficacy := TypeChart.get_attacking_type_efficacy(TypeChart.Type.NONE, owner.type)
	var attacking_stage_multi := owner.get_stat_stage_multi(Monster.Stat.ATTACK)
	var attacking_stat := owner.attack * attacking_stage_multi
	var attacking_multi = owner.stat_multis.stat_multipliers[Monster.Stat.ATTACK]
	var defending_stage_multi := owner.get_stat_stage_multi(Monster.Stat.DEFENSE)
	var defending_stat := owner.defense * defending_stage_multi
	var defending_multi = owner.stat_multis.stat_multipliers[Monster.Stat.DEFENSE]
	var level_based_damage = (((2 * owner.level) / 5.0) + 2)
	var scaling_based_damage = self_hit_power * (attacking_stat / defending_stat)
	var final_damage = (((level_based_damage * scaling_based_damage) / 50.0) + 2) * efficacy * attacking_multi * defending_multi
	return int(ceil(final_damage))
