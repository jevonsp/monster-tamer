extends Resource
class_name TypeChart

enum Type {
	FIRE,
	WATER,
	GRASS,
}

static var efficacy: Dictionary = {
	not_very = 0.5,
	normal = 1.0,
	super_effective = 2.0,
}

static var type_chart: Dictionary = {
	Type.FIRE: {
		Type.FIRE: &"normal",
		Type.WATER: &"not_very",
		Type.GRASS: &"super_effective",
	},
	Type.WATER: {
		Type.FIRE: &"super_effective",
		Type.WATER: &"normal",
		Type.GRASS: &"not_very",
	},
	Type.GRASS: {
		Type.FIRE: &"not_very",
		Type.WATER: &"super_effective",
		Type.GRASS: &"normal",
	},
}

static func get_type_efficacy(attacker: Type, defender: Type) -> float:
	return type_chart[attacker][defender]
