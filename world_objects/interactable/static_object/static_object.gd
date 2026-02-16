extends StaticBody2D

@export_multiline var text: Array[String] = [""]
@export var is_autocomplete: bool = false
@export var is_question: bool = false

func interact(body: CharacterBody2D) -> void:
	if not body.is_in_group("player"):
		printerr("Static Obj %s interacted with by Body %s,\nThis should never happen.\nExiting interact()")
		return
	if text != [""]:
		Global.send_overworld_text_box.emit(self, text, is_autocomplete, is_question)
