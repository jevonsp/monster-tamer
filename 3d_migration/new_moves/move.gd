class_name Move
extends Resource

@export var name: String = ""
@export_range(-7, 7, 1) var priority: int = 0
@export var actions: ActionList = null
@export var target_type: Choice.Target = Choice.Target.ENEMY
@export var base_pp: int = 20
@export_multiline() var description: String
@export_enum("test") var animation_name: String = "test"


func get_animation_name() -> StringName:
	return StringName(animation_name)
