class_name Move
extends Resource

@export var name: String = ""
@export var type: TypeChart.Type
@export var base_power: int = 3
@export_range(-5, 5) var priority: int = 0
@export var animation: PackedScene
@export var is_self_targeting: bool = false
@export_multiline var description: String = ""


func execute(actor: Monster, target: Monster, battle_context: BattleContext):
	var damage = ceili(base_power * TypeChart.get_attacking_type_efficacy(type, target.type))
	var efficacy = TypeChart.get_attacking_type_efficacy(type, target.type)
	
	battle_context.show_move_used_text(actor, name, target)
	
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
