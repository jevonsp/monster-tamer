extends TextureRect

var actor: Monster = null


func set_actor(a: Monster, update: bool = true) -> void:
	actor = a
	if update:
		display()


func display() -> void:
	if not actor:
		texture = null
		return
	texture = actor.monster_data.texture
