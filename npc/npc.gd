class_name NPC
extends CharacterBody2D

@export_multiline var dialogue: Array[String] = [""]
@export var is_autocomplete: bool = false

func interact(body: CharacterBody2D) -> void:
	print("interact")
	_say_dialogue()


func _turn_to_body(body: CharacterBody2D) -> void:
	# Get dir then turn_to_dir(dir)
	pass


func _turn_to_dir(dir: Vector2) -> void:
	pass


func _say_dialogue(d: Array[String] = [""], autocomplete = null) -> void:
	var dia = d if d != [""] else dialogue
	var ac = autocomplete if autocomplete != null else is_autocomplete
	Global.send_overworld_text_box.emit(dia, ac)
