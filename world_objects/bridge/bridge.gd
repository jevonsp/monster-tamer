extends Node2D

## When [method TileMover.sync_height_from_stand_tile] reports this level, rail StaticBody2D
## children use their scene collision_layer. Otherwise layers are cleared so the player can pass under.
@export var rails_active_at_height_level: int = 1

var _rail_default_layers: Dictionary # StaticBody2D -> int


func _ready() -> void:
	for c in get_children():
		if c is StaticBody2D:
			_rail_default_layers[c] = c.collision_layer
	_update_rail_collision()


func _physics_process(_delta: float) -> void:
	_update_rail_collision()


func _update_rail_collision() -> void:
	if Engine.is_editor_hint():
		for body in _rail_default_layers:
			if is_instance_valid(body):
				body.collision_layer = _rail_default_layers[body]
		return

	var player := get_tree().get_first_node_in_group("player") as TileMover
	var rails_on: bool = (
		player != null and player.height_level == rails_active_at_height_level
	)
	for body in _rail_default_layers:
		if not is_instance_valid(body):
			continue
		body.collision_layer = _rail_default_layers[body] if rails_on else 0
