extends Label

var actor = null
var label_level


func _ready() -> void:
	Battle.monster_gained_level.connect(_on_monster_gained_level)


func update():
	if actor != null:
		label_level = actor.level
		text = "Lvl. %s" % [label_level]
	else:
		text = ""


func _on_monster_gained_level(monster: Monster, amount: int) -> void:
	if actor == monster:
		label_level += amount
		text = "Lvl. %s" % [label_level]
