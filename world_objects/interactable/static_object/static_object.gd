class_name StaticObject
extends StaticBody2D

@export_multiline var text: Array[String] = []
@export var is_autocomplete: bool = false
@export var is_question: bool = false
@export var components: Array[Node]


func interact(body: CharacterBody2D) -> void:
	if not body.is_in_group("player"):
		printerr("Static Obj %s interacted with by Body %s,\nThis should never happen.\nExiting interact()")
		return
	if not text.is_empty():
		var tp = true # Toggles Player
		Ui.send_text_box.emit(self, text, is_autocomplete, is_question, tp)


func trigger() -> void:
	for component in components:
		component.trigger()
