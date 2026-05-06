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
	if actor.is_shiny:
		texture = actor.monster_data.shiny_front_texture
	else:
		texture = actor.monster_data.base_front_texture
