extends Button

var actor: Monster = null

@onready var label: Label = $Label


func set_actor(a: Monster, update: bool = false) -> void:
	if not a:
		actor = null
		return
	actor = a
	if update:
		display()


func display() -> void:
	var idx = int(name)
	if not actor:
		label.text = ""
		return
	var move = actor.moves[idx]
	if move:
		label.text = move.name
