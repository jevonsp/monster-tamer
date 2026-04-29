extends Label

var actor: Monster = null


func update() -> void:
	if actor != null:
		text = "Level: %s" % actor.level
	else:
		text = ""
