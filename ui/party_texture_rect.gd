extends TextureRect
var actor = null

func update():
	if actor != null:
		texture = actor.monster_data.texture
	else:
		texture = null
