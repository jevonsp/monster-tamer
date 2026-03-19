extends Resource
class_name MonsterStatMultipliers

var stat_stages: Dictionary = {
	Monster.Stat.ATTACK: 0,
	Monster.Stat.SPECIAL_ATTACK: 0,
	Monster.Stat.DEFENSE: 0,
	Monster.Stat.SPECIAL_DEFENSE: 0,
	Monster.Stat.SPEED: 0,
	Monster.Stat.ACCURACY: 0,
	Monster.Stat.EVASION: 0,
	Monster.Stat.CRITICAL: 0,
}
var stat_multipliers: Dictionary = {
	Monster.Stat.ATTACK: 1.0,
	Monster.Stat.SPECIAL_ATTACK: 1.0,
	Monster.Stat.DEFENSE: 1.0,
	Monster.Stat.SPECIAL_DEFENSE: 1.0,
	Monster.Stat.SPEED: 1.0,
	Monster.Stat.ACCURACY: 1.0,
	Monster.Stat.EVASION: 1.0,
}
