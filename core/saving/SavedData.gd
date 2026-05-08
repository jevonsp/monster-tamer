class_name SavedData
extends Resource

@export var position: Vector3 = Vector3.ZERO
@export var facing_grid: Vector3i = Vector3i(0, 0, 1)
@export var node_path: NodePath
@export var inventory: Variant = null
@export var is_active: bool = true
@export var blocks_player: bool = false
@export var masks_player: bool = true
@export var is_visible: bool = true
