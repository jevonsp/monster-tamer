extends TextureRect

const UP_ARROW = preload("uid://cx1kq2j7nown8")
const DOWN_ARROW = preload("uid://borvjxgoof7ao")

var actor: Monster = null


func set_actor(a: Monster, update: bool = true) -> void:
	if not a:
		actor = null
		return
	actor = a
	if update:
		display()


func display(move: Move = null, target: Monster = null) -> void:
	if not move or not target:
		display_normal_effective()
		return
	var efficacy = TypeChart.get_attacking_type_efficacy(move.type, target)
	if efficacy > 1.0:
		display_super_effective()
	elif efficacy < 1.0:
		display_not_very_effective()
	elif efficacy == 1.0:
		display_normal_effective()


func display_super_effective() -> void:
	texture = UP_ARROW


func display_not_very_effective() -> void:
	texture = null


func display_normal_effective() -> void:
	texture = DOWN_ARROW
