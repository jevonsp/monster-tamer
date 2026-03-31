class_name SavedData
extends Resource

@export var position: Vector2 = Vector2.ZERO
@export var facing_dir: TileMover.Direction = TileMover.Direction.NONE
@export var node_path: NodePath
@export var state: int = 0
@export var is_obtained: bool = false
@export var is_defeated: bool = false
@export var inventory: Variant = null
