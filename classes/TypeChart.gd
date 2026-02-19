extends Resource
class_name TypeChart

enum Type {
	FIRE,
	WATER,
	GRASS,
}

const NOT_VERY := 0.5
const NORMAL := 1.0
const SUPER_EFFECTIVE := 2.0

static var type_chart: Dictionary = {
	Type.FIRE: {
		Type.FIRE: NORMAL,
		Type.WATER: NOT_VERY,
		Type.GRASS: SUPER_EFFECTIVE,
	},
	Type.WATER: {
		Type.FIRE: SUPER_EFFECTIVE,
		Type.WATER: NORMAL,
		Type.GRASS: NOT_VERY,
	},
	Type.GRASS: {
		Type.FIRE: NOT_VERY,
		Type.WATER: SUPER_EFFECTIVE,
		Type.GRASS: NORMAL,
	},
}

static func get_type_efficacy(attacker: Type, defender: Type) -> float:
	return type_chart[attacker][defender]
