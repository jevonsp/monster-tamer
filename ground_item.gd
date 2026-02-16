extends StaticObject
class_name GroundItem

func interact(body: CharacterBody2D) -> void:
	super(body)
	if not is_question:
		await Global.overworld_text_box_complete
		trigger()

func trigger() -> void:
	print("Would give item here")
