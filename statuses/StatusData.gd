extends Resource
class_name StatusData

@export var status_name: String = ""
@export var default_duration: int = 3


func on_apply(_owner: Monster, _context: BattleContext) -> void:
	pass


func on_turn_start(_owner: Monster, _context: BattleContext) -> void:
	pass


func on_turn_end(_owner: Monster, _context: BattleContext) -> void:
	pass


func on_remove(_owner: Monster, _context: BattleContext) -> void:
	pass
