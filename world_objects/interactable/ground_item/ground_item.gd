extends StaticObject
class_name GroundItem
@export var is_obtained: bool = false:
	set(value):
		is_obtained = value
		if is_obtained:
			visible = false
			collision_shape_2d.disabled = true
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func interact(body: CharacterBody2D) -> void:
	super(body)
	if not is_question:
		await Global.overworld_text_box_complete
		trigger()


func trigger() -> void:
	print("Would give item here")
	obtain()

func obtain() -> void:
	is_obtained = true
