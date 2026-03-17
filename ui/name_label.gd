extends Label
var actor: Monster = null

func update() -> void:
	if actor != null:
		text = actor.name
	else:
		text = ""
