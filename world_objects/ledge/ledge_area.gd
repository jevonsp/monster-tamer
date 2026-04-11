extends Area2D

@export var allowed_direction: TileMover.Direction = TileMover.Direction.NONE


func _ready() -> void:
	add_to_group("ledge")
