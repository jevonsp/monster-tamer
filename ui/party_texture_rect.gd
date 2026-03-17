extends TextureRect
var actor: Monster = null

func update() -> void:
	if actor != null:
		texture = actor.monster_data.texture
	else:
		texture = null
