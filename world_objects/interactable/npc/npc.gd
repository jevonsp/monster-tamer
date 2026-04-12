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
@export var before_components: Array[NPCComponent] = []
@export var after_components: Array[NPCComponent] = []

var tiles_in_sight: Array[Vector2] = []
var last_dialogue_yes_no: bool = false
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
		MoveState.JUMPING:
			pass


func interact(body: CharacterBody2D) -> void:
	var interfaces := get_tree().get_first_node_in_group("interfaces")
	if interfaces and interfaces.has_method("begin_field_suppress"):
		interfaces.begin_field_suppress()
	await _interact_impl(body)
	if interfaces and interfaces.has_method("end_field_suppress"):
		interfaces.end_field_suppress()


func trigger() -> void:
	var player = get_tree().get_first_node_in_group("player")
	for c: NPCComponent in npc_components:
		if c is NPCBlockerComponent or not c.is_active:
			continue
		@warning_ignore("redundant_await")
		var result = await c.trigger(player)
		match result:
			NPCComponent.Result.CONTINUE:
				pass
			NPCComponent.Result.CONSUME:
				var idx: int = npc_components.find(c)
				if idx >= 0 and idx + 1 < npc_components.size():
					npc_components[idx + 1].is_active = false
			NPCComponent.Result.TERMINATE:
				return
	if story_component:
		story_component.trigger()


func animate_exclamation() -> void:
	exclamation_point.visible = true
	exclamation_point.play()
	await exclamation_point.animation_finished
	await get_tree().create_timer(0.1).timeout
	exclamation_point.visible = false


func _interact_impl(body: CharacterBody2D) -> void:
	await _turn_to_body(body)
	var blocker := _find_blocker_component()
	if blocker and blocker.state == NPCBlockerComponent.State.INCOMPLETE:
		if blocker.mode == NPCBlockerComponent.Mode.ITEM:
			if await blocker.try_item_interact(body):
				return
	if blocker and blocker.state == NPCBlockerComponent.State.COMPLETE:
		await blocker.run_post_complete_interact(body)
		await _invoke_components_phase(after_components)
		return
	var service := _find_service_component()
	if service and service.state == NPCServiceComponent.State.COMPLETE:
		await service.run_post_complete_interact(body)
		return
	if service and await service.try_trade_interact(body):
		return

	await _invoke_components_phase(before_components)

	if not dialogue.is_empty():
		await _say_dialogue()

	await _invoke_components_phase(after_components)


func _invoke_components_phase(list: Array[NPCComponent]) -> void:
	var player = get_tree().get_first_node_in_group("player")
	for c: NPCComponent in list:
		if c is NPCBlockerComponent:
			continue
		if c.is_active:
			@warning_ignore("redundant_await")
			var result = await c.trigger(player)
			match result:
				NPCComponent.Result.CONTINUE:
					pass
				NPCComponent.Result.CONSUME:
					var idx: int = list.find(c)
					if idx >= 0 and idx + 1 < list.size():
						list[idx + 1].is_active = false
				NPCComponent.Result.TERMINATE:
					return


func _turn_to_body(body) -> void:
	var toward_player: Vector2 = _get_step_direction_to(body.global_position)
	if toward_player != Vector2.ZERO and toward_player != facing_vec:
		await start_turning(toward_player)


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
	if iq:
		last_dialogue_yes_no = await Ui.answer_given
		await Ui.text_box_complete
		if last_dialogue_yes_no:
			await trigger()
	else:
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


func _find_blocker_component() -> NPCBlockerComponent:
	for c: NPCComponent in npc_components:
		if c is NPCBlockerComponent:
			return c as NPCBlockerComponent
	return null


func _find_service_component() -> NPCServiceComponent:
	for c: NPCComponent in npc_components:
		if c is NPCServiceComponent:
			return c as NPCServiceComponent
	return null
