extends Node
class_name MonsterStatTable

static var stat_properties: Dictionary = {
	Monster.Stat.ATTACK: &"attack",
	Monster.Stat.SPECIAL_ATTACK: &"special_attack",
	Monster.Stat.DEFENSE: &"defense",
	Monster.Stat.SPECIAL_DEFENSE: &"special_defense",
	Monster.Stat.SPEED: &"speed",
}

static func get_stat_enum(stat_name: StringName) -> Monster.Stat:
	for key in stat_properties:
		if stat_properties[key] == stat_name:
			return key
	return Monster.Stat.ATTACK

# gdlint:ignore-block-start
static var normal_stat_multis: Dictionary = {
	-6: 2/8.0,-5: 2/7.0,-4: 2/6.0,-3: 2/5.0,-2: 2/4.0,-1: 2/3.0,
	0: 2/2.0,
	1: 3/2.0, 2: 4/2.0, 3: 5/2.0, 4: 6/2.0, 5: 7/2.0, 6: 8/2.0,
}
static var special_stat_multis: Dictionary = {
	-6: 3/9.0, -5: 3/8.0, -4: 3/7.0, -3: 3/6.0, -2: 3/5.0, -1: 3/4.0,
	0: 3/3.0,
	1: 4/3.0, 2: 5/3.0, 3: 6/3.0, 4: 7/3.0, 5: 8/3.0, 6: 9/3.0,
}
static var critical_stage_multi: Dictionary = {
	0: 1/16.0,
	1: 1/8.0,
	2: 1/4.0,
	3: 1/2.0,
	4: 1
}
# gdlint:ignore-block-end
