extends Label

var actor: Monster = null


func set_actor(a: Monster, update: bool = true) -> void:
	if not a:
		actor = null
		return
	actor = a
	if update:
		display()


func display() -> void:
	if not actor:
		text = ""
		return
	text = "Lvl. %s" % [actor.level]
