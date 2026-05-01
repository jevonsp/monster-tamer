extends TextureRect

var actor: Monster = null


func set_actor(a: Monster, update: bool = false) -> void:
	if not a:
		actor = null
		return
	actor = a
	if update:
		display()


func display(move: Move = null) -> void:
	if not move:
		_toggle_visible(false)
		return
	if not actor:
		return
	if move.type == actor.primary_type:
		_toggle_visible(true)
		return
	if move.type == actor.secondary_type and actor.secondary_type != null:
		_toggle_visible(true)
		return
	_toggle_visible(false)


func _toggle_visible(val: bool) -> void:
	visible = val
