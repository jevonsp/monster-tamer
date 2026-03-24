class_name TypeChart
extends Resource

enum Type {
	NONE,
	FIRE,
	WATER,
	GRASS,
	AIR,
	EARTH
}

const NOT_VERY: float = 0.5
const NORMAL: float = 1.0
const SUPER_EFFECTIVE: float = 2.0

# TYPE_CHART_GENERATED_BEGIN
const TYPE_CHART: Dictionary = {
	Type.NONE: {
		Type.NONE: NORMAL,
		Type.FIRE: NORMAL,
		Type.WATER: NORMAL,
		Type.GRASS: NORMAL,
		Type.AIR: NORMAL,
		Type.EARTH: NOT_VERY,
	},
	Type.FIRE: {
		Type.NONE: NORMAL,
		Type.FIRE: NORMAL,
		Type.WATER: NOT_VERY,
		Type.GRASS: SUPER_EFFECTIVE,
		Type.AIR: SUPER_EFFECTIVE,
		Type.EARTH: NOT_VERY,
	},
	Type.WATER: {
		Type.NONE: NORMAL,
		Type.FIRE: SUPER_EFFECTIVE,
		Type.WATER: NORMAL,
		Type.GRASS: NOT_VERY,
		Type.AIR: NORMAL,
		Type.EARTH: SUPER_EFFECTIVE,
	},
	Type.GRASS: {
		Type.NONE: NORMAL,
		Type.FIRE: NOT_VERY,
		Type.WATER: SUPER_EFFECTIVE,
		Type.GRASS: NORMAL,
		Type.AIR: NOT_VERY,
		Type.EARTH: SUPER_EFFECTIVE,
	},
	Type.AIR: {
		Type.NONE: NORMAL,
		Type.FIRE: NOT_VERY,
		Type.WATER: NORMAL,
		Type.GRASS: NORMAL,
		Type.AIR: NORMAL,
		Type.EARTH: SUPER_EFFECTIVE,
	},
	Type.EARTH: {
		Type.NONE: NORMAL,
		Type.FIRE: SUPER_EFFECTIVE,
		Type.WATER: NORMAL,
		Type.GRASS: NORMAL,
		Type.AIR: NORMAL,
		Type.EARTH: NOT_VERY,
	},
}
# TYPE_CHART_GENERATED_END

static func get_attacking_type_efficacy(attacker: Type, defender: Type) -> float:
	return TYPE_CHART[attacker][defender]
