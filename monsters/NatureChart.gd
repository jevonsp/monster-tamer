extends Resource
class_name NatureChart

const NATURES = {
	"Hardy": { "increase": Monster.Stat.NONE, "decrease": Monster.Stat.NONE },
	"Lonely": { "increase": Monster.Stat.ATTACK, "decrease": Monster.Stat.DEFENSE },
	"Brave": { "increase": Monster.Stat.ATTACK, "decrease": Monster.Stat.SPEED },
	"Adamant": { "increase": Monster.Stat.ATTACK, "decrease": Monster.Stat.SPECIAL_ATTACK },
	"Naughty": { "increase": Monster.Stat.ATTACK, "decrease": Monster.Stat.SPECIAL_DEFENSE },
	"Bold": { "increase": Monster.Stat.DEFENSE, "decrease": Monster.Stat.ATTACK },
	"Docile": { "increase": Monster.Stat.NONE, "decrease": Monster.Stat.NONE },
	"Relaxed": { "increase": Monster.Stat.DEFENSE, "decrease": Monster.Stat.SPEED },
	"Impish": { "increase": Monster.Stat.DEFENSE, "decrease": Monster.Stat.SPECIAL_ATTACK },
	"Lax": { "increase": Monster.Stat.DEFENSE, "decrease": Monster.Stat.SPECIAL_DEFENSE },
	"Timid": { "increase": Monster.Stat.SPEED, "decrease": Monster.Stat.ATTACK },
	"Hasty": { "increase": Monster.Stat.SPEED, "decrease": Monster.Stat.DEFENSE },
	"Serious": { "increase": Monster.Stat.NONE, "decrease": Monster.Stat.NONE },
	"Jolly": { "increase": Monster.Stat.SPEED, "decrease": Monster.Stat.SPECIAL_ATTACK },
	"Naive": { "increase": Monster.Stat.SPEED, "decrease": Monster.Stat.SPECIAL_DEFENSE },
	"Modest": { "increase": Monster.Stat.SPECIAL_ATTACK, "decrease": Monster.Stat.ATTACK },
	"Mild": { "increase": Monster.Stat.SPECIAL_ATTACK, "decrease": Monster.Stat.DEFENSE },
	"Quiet": { "increase": Monster.Stat.SPECIAL_ATTACK, "decrease": Monster.Stat.SPEED },
	"Bashful": { "increase": Monster.Stat.NONE, "decrease": Monster.Stat.NONE },
	"Rash": { "increase": Monster.Stat.SPECIAL_ATTACK, "decrease": Monster.Stat.SPECIAL_DEFENSE },
	"Calm": { "increase": Monster.Stat.SPECIAL_DEFENSE, "decrease": Monster.Stat.ATTACK },
	"Gentle": { "increase": Monster.Stat.SPECIAL_DEFENSE, "decrease": Monster.Stat.DEFENSE },
	"Sassy": { "increase": Monster.Stat.SPECIAL_DEFENSE, "decrease": Monster.Stat.SPEED },
	"Careful": { "increase": Monster.Stat.SPECIAL_DEFENSE, "decrease": Monster.Stat.SPECIAL_ATTACK },
	"Quirky": { "increase": Monster.Stat.NONE, "decrease": Monster.Stat.NONE }
}


static func get_random_nature() -> String:
	var natures = NATURES.keys()
	return natures[randi() % natures.size()]


static func get_nature_effect(nature_name: String) -> Dictionary:
	return NATURES.get(nature_name, { "increase": Monster.Stat.NONE, "decrease": Monster.Stat.NONE })


static func get_nature_multiplier(nature_name: String, stat: Monster.Stat) -> float:
	var effect = get_nature_effect(nature_name)
	if effect["increase"] == stat:
		return 1.1
	elif effect["decrease"] == stat:
		return 0.9
	return 1.0
