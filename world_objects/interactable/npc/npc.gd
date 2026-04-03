@tool
class_name NPC
extends TileMover

@export var npc_name: String = "NPC"
@export var direction: Direction = Direction.DOWN:
	set(value):
		direction = value
		if Engine.is_editor_hint():
			_update_direction_visual()
@export_multiline var dialogue: Array[String] = []
@export var is_autocomplete: bool = false
@export var is_question: bool = false

var tiles_in_sight: Array[Vector2] = []
var npc_components: Array[NPCComponent] = []
var story_component: StoryComponent = null
var facing_vec: Vector2:
	get:
		return facing_direction
	set(value):
		facing_direction = value

@onready var exclamation_point: AnimatedSprite2D = $ExclamationPoint


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		_update_direction_visual()
		return
	_set_components()
	_connect_signals()
	_update_direction_visual()


func _physics_process(delta: float) -> void:
	match current_state:
		MoveState.MOVING:
			animate_move(delta)


func interact(body: CharacterBody2D) -> void:
	var toward_player: Vector2 = _get_step_direction_to(body.global_position)
	if toward_player != Vector2.ZERO and toward_player != facing_vec:
		start_turning(toward_player)
	if not dialogue.is_empty():
		await _say_dialogue()
	else:
		await trigger()


func trigger() -> void:
	var player = get_tree().get_first_node_in_group("player")
	for c: NPCComponent in npc_components:
		if c.is_active:
			@warning_ignore("redundant_await")
			await c.trigger(player)
	if story_component:
		story_component.trigger()


func animate_exclamation() -> void:
	exclamation_point.visible = true
	exclamation_point.play()
	await exclamation_point.animation_finished
	await get_tree().create_timer(0.1).timeout
	exclamation_point.visible = false


func _set_components() -> void:
	for child in get_children():
		if child is NPCComponent:
			npc_components.append(child)
		if child is StoryComponent:
			story_component = child


func _connect_signals() -> void:
	if Engine.is_editor_hint():
		return


func _say_dialogue(d: Array[String] = [], autocomplete = null, question = null) -> void:
	var dia = d if not d.is_empty() else dialogue
	var ac = autocomplete if autocomplete != null else is_autocomplete
	var iq = question if question != null else is_question
	Ui.send_text_box.emit(self, dia, ac, iq, true)
	await Ui.text_box_complete


func _update_direction_visual() -> void:
	if not is_node_ready():
		return

	var anim_player = get_node("AnimationPlayer") as AnimationPlayer
	if not anim_player:
		return

	var dir_vec = _vector_from_dir(direction)
	facing_direction = dir_vec

	ray_cast_2d.target_position = facing_direction * TILE_SIZE
	ray_cast_2d.force_raycast_update()

	if animation_tree:
		animation_tree.set("parameters/Idle/blend_position", dir_vec)
		anim_state.travel("Idle")
	else:
		anim_state.travel("Idle")


func _get_walk_speed() -> float:
	return 4.0
