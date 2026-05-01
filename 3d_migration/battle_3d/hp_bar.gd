extends TextureProgressBar

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
		value = 100.0
		max_value = 100.0
		return
	max_value = actor.max_hitpoints * 100
	value = actor.current_hitpoints * 100
