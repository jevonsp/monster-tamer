extends TileMapLayer

@export var is_elevated: bool = false
@export var is_barrier: bool = false


func _ready() -> void:
	if is_elevated:
		Global.elevated_map = self
	else:
		Global.base_map = self

	if is_barrier:
		visible = false
