class_name HeldEffect
extends Resource

enum EffectType { NONE, STAT_BOOST, TYPE_BOOST, HEALING, EXPERIENCE }
enum BoostType { NONE, FLAT, PERCENTAGE }

@export var effect_type: EffectType = EffectType.NONE
@export var boost_type: BoostType = BoostType.NONE
@export_range(-1.0, 1.0, 0.05) var percentage_boost_amount: float = 0.1
@export var flat_boost_amount: int = 20
@export var stat: Monster.Stat = Monster.Stat.NONE
@export var type: TypeChart.Type = TypeChart.Type.NONE
@export var healing_type: BoostType = BoostType.NONE
@export var experience_boost_type: BoostType = BoostType.NONE


func get_flat_bonus() -> int:
	return flat_boost_amount


func get_percent_bonus() -> float:
	return percentage_boost_amount
