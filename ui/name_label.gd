extends Label
var actor

func update():
	if actor != null:
		text = actor.name
	else:
		text = ""
