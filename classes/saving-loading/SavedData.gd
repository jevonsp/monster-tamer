extends Resource
class_name SavedData

@export var position: Vector2 = Vector2.ZERO
@export var node_path: NodePath

@export var state: int = 0
@export var is_obtained: bool = false
@export var is_defeated: bool = false
@export var inventory: Variant = null
