extends Resource
class_name Switch
@export_range(-5, 5) var priority: int = 5
var actor: Monster
var target: Monster
var out_unformatted: String = "Thats enough, %s!"
var in_unformatted: String = "Its your turn, %s"

func execute(old: Monster, new: Monster, battle_context: BattleContext) -> void:
	await battle_context.perform_switch(old, new, out_unformatted, in_unformatted)
