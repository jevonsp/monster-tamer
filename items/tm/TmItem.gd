class_name TmItem
extends Item


func get_display_name() -> String:
	return name.format({ "move": (use_effect.move as Move).name })


func get_display_description() -> String:
	return description.format({ "move": (use_effect.move as Move).name })
