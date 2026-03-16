extends StatusData
class_name DoTStatus

@export var damage_per_turn: int = 2


func on_turn_start(owner_monster: Monster, _context: BattleContext) -> void:
	await owner_monster.take_damage(damage_per_turn)
	await owner_monster.check_faint()
