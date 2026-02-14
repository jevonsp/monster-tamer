@tool
class_name NPC
extends CharacterBody2D
enum Direction {UP, DOWN, LEFT, RIGHT}
@export var direction: Direction = Direction.DOWN:
	set(value):
		direction = value
		if Engine.is_editor_hint():
			_update_direction_visual()
@export_multiline var dialogue: Array[String] = [""]
@export var is_autocomplete: bool = false
@export var is_question: bool = false
@export var facing_dir: Vector2 = Vector2.DOWN
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
	if dir == get_vector():
		return
	_turn_to_dir(dir)


func _turn_to_dir(dir: Vector2) -> void:
	match dir:
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


func get_vector() -> Vector2:
	match direction:
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


func _say_dialogue(d: Array[String] = [""], autocomplete = null, question = null) -> void:
	var dia = d if d != [""] else dialogue
	var ac = autocomplete if autocomplete != null else is_autocomplete
	var iq = question if question != null else is_question
	Global.send_overworld_text_box.emit(self, dia, ac, iq)
	
	
func trigger() -> void:
	print_debug("NPC got Trigger")
	var player = get_tree().get_first_node_in_group("player")
	for c in components:
		c.trigger(player)
