@tool
class_name NPC
extends CharacterBody2D
enum Direction {NONE, UP, DOWN, LEFT, RIGHT}
const TILE_SIZE: int = 16
@export var direction: Direction = Direction.DOWN:
	set(value):
		direction = value
		if Engine.is_editor_hint():
			_update_direction_visual()
@export_multiline var dialogue: Array[String] = [""]
@export var is_autocomplete: bool = false
@export var is_question: bool = false
@export var facing_vec: Vector2 = Vector2.DOWN
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var components: Array[NPCComponent] = []

func _ready() -> void:
	if Engine.is_editor_hint():
		_update_direction_visual()
	_set_component_array()


func _set_component_array() -> void:
	for child in get_children():
		if child is NPCComponent:
			components.append(child)


func _update_direction_visual() -> void:
	if not is_node_ready():
		return
		
	if not has_node("AnimationPlayer"):
		return
		
	var anim_player = get_node("AnimationPlayer") as AnimationPlayer
	if not anim_player:
		return
		
	match direction:
		Direction.UP:
			animation_player.play("TurnUp")
		Direction.DOWN:
			animation_player.play("TurnDown")
		Direction.LEFT:
			animation_player.play("TurnLeft")
		Direction.RIGHT:
			animation_player.play("TurnRight")


func interact(body: CharacterBody2D) -> void:
	_turn_to_body(body)
	_say_dialogue()


func _turn_to_body(body: CharacterBody2D) -> void:
	var dir = (body.global_position - global_position).normalized()
	if dir == _vector_from_dir(direction):
		return
	_turn_to_vec(dir)


func _turn_to_vec(vec: Vector2) -> void:
	match vec:
		Vector2.UP:
			animation_player.play("TurnUp")
			direction = Direction.UP
		Vector2.DOWN:
			animation_player.play("TurnDown")
			direction = Direction.DOWN
		Vector2.LEFT:
			animation_player.play("TurnLeft")
			direction = Direction.LEFT
		Vector2.RIGHT:
			animation_player.play("TurnRight")
			direction = Direction.RIGHT
	facing_vec = _vector_from_dir(direction)
	print("would turn to %s" % [facing_vec])
	await animation_player.animation_finished


func _walk_to_tile(pos: Vector2) -> void:
	var vec = (pos - global_position)
	var dir = Direction.keys()[_direction_from_vector(vec.normalized())]
	var count: int
	if abs(vec.x) > 0:
		count = abs(int(vec.x / TILE_SIZE))
	else:
		count = abs(int(vec.y / TILE_SIZE))
	if not _is_facing(vec.normalized()):
		await _turn_to_vec(vec.normalized())
	_walk_tiles(dir, count)


func _walk_tiles(dir, count) -> void:
	print("%s tile in %s direction" % [count, dir])
	
	
func _is_facing(dir: Vector2) -> bool:
	return _vector_from_dir(direction) == dir


func _vector_from_dir(dir: Direction) -> Vector2:
	match dir:
		Direction.UP:
			return Vector2.UP
		Direction.DOWN:
			return Vector2.DOWN
		Direction.LEFT:
			return Vector2.LEFT
		Direction.RIGHT:
			return Vector2.RIGHT
		_:
			return Vector2.ZERO


func _direction_from_vector(vector: Vector2) -> Direction:
	match vector:
		Vector2.UP:
			return Direction.UP
		Vector2.DOWN:
			return Direction.DOWN
		Vector2.LEFT:
			return Direction.LEFT
		Vector2.RIGHT:
			return Direction.RIGHT
		_:
			return Direction.NONE


func _say_dialogue(d: Array[String] = [""], autocomplete = null, question = null) -> void:
	var dia = d if d != [""] else dialogue
	var ac = autocomplete if autocomplete != null else is_autocomplete
	var iq = question if question != null else is_question
	Global.send_overworld_text_box.emit(self, dia, ac, iq)
	
	
func trigger() -> void:
	var player = get_tree().get_first_node_in_group("player")
	for c in components:
		c.trigger(player)


func _on_left_pressed() -> void:
	var tar = global_position + Vector2(-TILE_SIZE, 0)
	_walk_to_tile(tar)


func _on_right_pressed() -> void:
	var tar = global_position + Vector2(TILE_SIZE, 0)
	_walk_to_tile(tar)


func _on_up_pressed() -> void:
	var tar = global_position + Vector2(0, -TILE_SIZE)
	_walk_to_tile(tar)


func _on_down_pressed() -> void:
	var tar = global_position + Vector2(0, TILE_SIZE)
	_walk_to_tile(tar)
