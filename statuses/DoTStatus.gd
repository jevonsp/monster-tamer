extends StatusData
class_name DoTStatus

@export var damage_per_turn: int = 2


func on_turn_end(owner_monster: Monster, context: BattleContext) -> void:
	var ta: Array[String] = ["%s was hurt by it's %s." % [owner_monster.name, status_name]]
	await context.show_text(ta)
	await owner_monster.take_damage(damage_per_turn)
	await owner_monster.check_faint()
