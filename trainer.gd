@tool
extends NPC
class_name Trainer
@export var vision_range: int = 7:
	set(value):
		vision_range = value
		_update_tiles_in_sight()

func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		_update_tiles_in_sight()
		return
	_update_tiles_in_sight()


func _connect_signals() -> void:
	super()
	Global.step_completed.connect(check_vision_collision)


func _update_tiles_in_sight() -> void:
	if not is_node_ready():
		return
	if tiles_in_sight == null:
		return
	tiles_in_sight.clear()
	var dir_vec = _vector_from_dir(direction)
	for i in range(1, vision_range):
		var tile = global_position + (dir_vec * TILE_SIZE * i)
		tiles_in_sight.append(tile)


func check_vision_collision(pos: Vector2) -> void:
	for i in range(len(tiles_in_sight)):
		if pos == tiles_in_sight[i]:
			Global.toggle_player.emit()
			await animate_exclamation()
			if i > 0:
				await walk_list_tiles([tiles_in_sight[i - 1]])
			_say_dialogue()
			return
