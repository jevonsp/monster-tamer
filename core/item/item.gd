class_name Item
extends Resource

enum Type { DEFAULT, RESTORE, BATTLE, BALL, KEY }

@export var name: String = ""
@export var item_type: Type = Type.DEFAULT
@export var can_be_used_in_battle: bool = false
@export var can_be_used_outside_battle: bool = false
@export var can_be_held: bool = false
@export var actions: ActionList = null
@export var texture: Texture2D = null
@export_multiline() var description: String
@export_range(-7, 7, 1) var priority: int = 7
