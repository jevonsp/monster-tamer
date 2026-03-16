extends MoveEffect
class_name DamageEffect

@export var type: TypeChart.Type
@export var base_power: int = 3
enum DamageType { PHYSICAL, SPECIAL }
@export var damage_type: DamageType = DamageType.PHYSICAL


func apply(actor: Monster, target: Monster, context: BattleContext, move_name: String = "attack", animation: PackedScene = null) -> void:
	var efficacy := TypeChart.get_attacking_type_efficacy(type, target.type)
	var damage := ceili(base_power * efficacy)

	await context.show_move_used_text(actor, move_name, target)
	if animation != null:
		await context.play_move_animation(animation)
	context.play_hit_reaction(target)
	await target.take_damage(damage)

	var lines: Array[String] = ["It dealt %s damage!" % damage]
	if efficacy > 1.0:
		lines[0] += "\nIt's super effective!"
	elif efficacy < 1.0:
		lines[0] += "\nIt's not very effective..."

	await context.show_move_result_text(lines)
	await target.check_faint()


func calculate_damage(actor: Monster, target: Monster) -> int:
	var efficacy := TypeChart.get_attacking_type_efficacy(type, target.type)
	return 1
