class_name Item
extends Resource

enum Type { DEFAULT, RESTORE, BATTLE, BALL, KEY }

@export var name: String = ""
@export_range(-7, 7, 1) var priority: int = 7
@export var actions: ActionList = null
