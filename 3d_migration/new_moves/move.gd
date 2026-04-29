class_name Move
extends Resource

@export var name: String = ""
@export_range(-7, 7, 1) var priority: int = 0
@export var actions: ActionList = null
