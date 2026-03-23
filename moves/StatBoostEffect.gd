extends MoveEffect
class_name StatBoostEffect

@export var stat: Monster.Stat = Monster.Stat.ATTACK
@export_range(-6, 6) var stage_amount: int = 1

func apply(
	_actor: Monster,
	target: Monster,
	context: BattleContext,
	_move_name: String = "",
	_animation: PackedScene = null
) -> void:
	pass
