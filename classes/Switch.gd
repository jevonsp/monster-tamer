extends Resource
class_name Switch
@export_range(-5, 5) var priority: int = 5
var actor: Monster
var target: Monster
var out_unformatted: String = "Thats enough, %s!"
var in_unformatted: String = "Its your turn, %s"

func execute(old: Monster, new: Monster, battle_context: BattleContext) -> void:
	print_debug("BATTLE: Switch.execute old=%s new=%s" % [old.name if old else "null", new.name if new else "null"])
	await battle_context.perform_switch(old, new, out_unformatted, in_unformatted)
	print_debug("BATTLE: Switch.execute complete old=%s new=%s" % [old.name if old else "null", new.name if new else "null"])
