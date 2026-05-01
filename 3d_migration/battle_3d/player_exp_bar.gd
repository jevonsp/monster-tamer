extends TextureProgressBar

var actor: Monster = null


func set_actor(a: Monster, update: bool = false) -> void:
	if not a:
		actor = null
		return
	actor = a
	if update:
		display()


func display() -> void:
	if not actor:
		value = 0.0
		max_value = 100.0
		return
