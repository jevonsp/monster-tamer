extends Label
var actor
var level

func _ready() -> void:
	Global.monster_gained_level.connect(_on_monster_gained_level)
	
	
func _on_monster_gained_level(monster: Monster, amount: int) -> void:
	if actor == monster:
		level += amount
		text = "Lvl. %s" % [level]
