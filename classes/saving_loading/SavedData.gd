class_name SavedData
extends Resource

@export var position: Vector3 = Vector3.ZERO
@export var facing_grid: Vector3i = Vector3i(0, 0, 1)
@export var node_path: NodePath
@export var state: int = 0
@export var is_obtained: bool = false
@export var is_defeated: bool = false
@export var inventory: Variant = null
