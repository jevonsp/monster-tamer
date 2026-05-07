extends TextureRect

var actor: Monster = null


func update() -> void:
	if actor != null:
		if actor.is_shiny:
			texture = actor.monster_data.shiny_front_texture
		else:
			texture = actor.monster_data.base_front_texture
	else:
		texture = null
