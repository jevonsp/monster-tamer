class_name Move
extends Resource

@export var name: String = ""
@export var type: TypeChart.Type
@export var base_power: int = 3
@export_range(-5, 5) var priority: int = 0
@export var animation: PackedScene
@export var is_self_targeting: bool = false
@export_multiline var description: String = ""

## If non-empty, execute runs these effects in order (animation passed to each). Otherwise uses legacy single-damage behavior.
@export var effects: Array[Resource] = []


func execute(actor: Monster, target: Monster, battle_context: BattleContext) -> void:
	if effects.is_empty():
		await _legacy_execute(actor, target, battle_context)
		return

	for effect in effects:
		if effect is MoveEffect:
			await effect.apply(actor, target, battle_context, name, animation)


func _legacy_execute(actor: Monster, target: Monster, battle_context: BattleContext) -> void:
	var damage = ceili(base_power * TypeChart.get_attacking_type_efficacy(type, target.type))
	var efficacy = TypeChart.get_attacking_type_efficacy(type, target.type)

	await battle_context.show_move_used_text(actor, name, target)
	await battle_context.play_move_animation(animation)

	battle_context.play_hit_reaction(target)
	await target.take_damage(damage)

	var post_text: Array[String] = []
	post_text.append("It dealt %s damage!" % [damage])
	if efficacy > 1.0:
		post_text[0] += "\nIt's super effective!"
	if efficacy < 1.0:
		post_text[0] += "\nIt's not very effective..."

	await battle_context.show_move_result_text(post_text)
	await target.check_faint()

