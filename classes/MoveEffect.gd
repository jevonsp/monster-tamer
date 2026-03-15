extends Resource
class_name MoveEffect
## Base for composable move effects. Move.execute runs each effect in order.

func apply(_actor: Monster, _target: Monster, _context: BattleContext, _move_name: String = "", _animation: PackedScene = null) -> void:
	pass
