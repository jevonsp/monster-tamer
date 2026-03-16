extends StatusData
class_name DoTStatus

@export var is_flat_damage: bool = false
@export var percent_damage_per_turn: float = 1/8.0
@export var flat_damage_per_turn: int = 2


func on_turn_end(_instance: StatusInstance, owner_monster: Monster, context: BattleContext) -> void:
	var ta: Array[String] = ["%s was hurt by it's %s." % [owner_monster.name, status_name]]
	await context.show_text(ta)
	if is_flat_damage:
		await owner_monster.take_damage(flat_damage_per_turn)
	else:
		var scaled_damage: int = max(1, owner_monster.max_hitpoints * percent_damage_per_turn)
		await owner_monster.take_damage(scaled_damage)
		
	await owner_monster.check_faint()
