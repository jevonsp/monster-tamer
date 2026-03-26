class_name StatModifierStatus
extends StatusData

@export var stat: Monster.Stat = Monster.Stat.SPEED
@export var multiplier: float = 1.0


func modify_effective_stat(
		_instance: StatusInstance,
		_owner: Monster,
		p_stat: Monster.Stat,
		value: float,
) -> float:
	if p_stat != stat:
		return value
	return value * multiplier
