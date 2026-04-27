class_name ItemEffect
extends Resource


func execute(_actor: Monster, _target: Monster, _battle_context: BattleContext) -> void:
	pass


func use(_target: Monster) -> bool:
	return false
