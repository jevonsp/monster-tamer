class_name NPCBlockerComponent
extends NPCComponent

enum Mode { STORY, ITEM }
enum Response { NONE, DISAPPEAR, MOVE, BESPOKE }
enum State { INCOMPLETE, COMPLETE }
enum ItemOutcome { NONE, GIVE, STORY }

@export var mode: Mode = Mode.STORY
@export var state: State = State.INCOMPLETE
@export_group("Story")
@export var story_trigger: Story.Flag = Story.Flag.NONE
@export var response_type: Response = Response.NONE
@export_group("Item")
@export var item_wanted: Item
@export var item_outcome: ItemOutcome = ItemOutcome.NONE
@export var item_to_give: Item = null
@export var story_flag: Story.Flag = Story.Flag.NONE
@export var story_value: bool = true
@export_group("Post-complete")
@export_multiline var post_trigger_dialogue: Array[String] = []
@export var is_autocomplete: bool = false
@export_subgroup("Move")
@export var dir_path: Array[TileMover.Direction] = []
@export var end_facing: TileMover.Direction = TileMover.Direction.NONE

var _collision_shape: CollisionShape2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("save_object")
	if mode == Mode.STORY:
		Global.story_flag_triggered.connect(_on_story_flag_triggered)
	var npc := get_parent()
	if npc:
		_collision_shape = npc.get_node_or_null("CollisionShape2D") as CollisionShape2D


func trigger(_player: Node) -> NPCComponent.Result:
	return NPCComponent.Result.CONTINUE


func try_item_interact(body: CharacterBody2D) -> bool:
	if mode != Mode.ITEM or state != State.INCOMPLETE:
		return false
	if not item_wanted:
		return false
	if body is not Player:
		return false
	var player := body as Player
	var inventory := player.inventory_handler.inventory as Dictionary[Item.Type, InventoryPage]
	for inv_page: InventoryPage in inventory.values():
		for item: Item in inv_page.page:
			if item == item_wanted:
				var ta: Array[String] = ["Perfect! I've been looking for that %s." % item_wanted.name]
				Ui.send_text_box.emit(null, ta, true, false, false)
				await Ui.text_box_complete

				ta = ["Would you like to trade it for my %s?" % item_to_give.name]
				Ui.send_text_box.emit(null, ta, false, true, false)
				var answer = await Ui.answer_given
				if answer:
					await _apply_item_outcome(player)
					await _finish_after_item_or_story()
					Global.toggle_player.emit()
					return true
				else:
					ta = ["That's too bad. I want that %s!" % item_wanted.name]
					Ui.send_text_box.emit(null, ta, true, false, false)
					await Ui.text_box_complete
					Global.toggle_player.emit()
					return true

	var fail: Array[String] = ["You don't have the %s I want.." % item_wanted.name]
	Ui.send_text_box.emit(null, fail, true, false, false)
	await Ui.text_box_complete
	Global.toggle_player.emit()
	return true


func run_post_complete_interact(body: CharacterBody2D) -> void:
	var npc := get_parent() as NPC
	if npc == null:
		return
	var toward_player: Vector2 = npc._get_step_direction_to(body.global_position)
	if toward_player != Vector2.ZERO and toward_player != npc.facing_vec:
		await npc.start_turning(toward_player)
	if not post_trigger_dialogue.is_empty():
		match mode:
			Mode.STORY:
				await npc._say_dialogue(post_trigger_dialogue, is_autocomplete)
			Mode.ITEM:
				await npc._say_dialogue(_format_post_trigger_lines(), true, false)


func on_save_game(saved_data_array: Array[SavedData]) -> void:
	var npc := get_parent() as NPC
	if npc == null:
		return
	var new_saved_data := SavedData.new()
	new_saved_data.node_path = npc.get_path()
	new_saved_data.state = state as int
	new_saved_data.position = npc.position
	new_saved_data.facing_dir = npc._direction_from_vector(npc.facing_vec)
	saved_data_array.append(new_saved_data)


func on_load_game(saved_data_array: Array[SavedData]) -> void:
	if not is_node_ready():
		await ready
	var npc := get_parent() as NPC
	if npc == null:
		return
	for data: SavedData in saved_data_array:
		if data.node_path == npc.get_path():
			state = data.state as State
			if state == State.COMPLETE:
				npc.position = data.position
				npc.direction = data.facing_dir as TileMover.Direction
				npc._update_direction_visual()
				_handle_completion()


func _item_name_for_post_dialogue() -> String:
	if item_wanted:
		return item_wanted.name
	if item_to_give:
		return item_to_give.name
	return ""


func _format_post_trigger_lines() -> Array[String]:
	var item_name := _item_name_for_post_dialogue()
	var out: Array[String] = []
	for line in post_trigger_dialogue:
		out.append(line.format({ "item": item_name }))
	return out


func _on_story_flag_triggered(flag: Story.Flag, _value: bool) -> void:
	if mode != Mode.STORY:
		return
	if flag != story_trigger:
		return
	var npc := get_parent() as NPC
	if npc == null:
		return
	Global.toggle_player.emit()
	match response_type:
		Response.NONE:
			Global.toggle_player.emit()
			return
		Response.DISAPPEAR:
			state = State.COMPLETE
		Response.MOVE:
			if not dir_path.is_empty():
				var vec_path: Array[Vector2] = []
				for dir in dir_path:
					vec_path.append(npc._vector_from_dir(dir))
				await npc.walk_list_dirs(vec_path)
			if end_facing != TileMover.Direction.NONE:
				var end_vec: Vector2 = npc._vector_from_dir(end_facing)
				await npc.start_turning(end_vec)
		Response.BESPOKE:
			pass
	state = State.COMPLETE
	_handle_completion()
	Global.toggle_player.emit()


func _finish_after_item_or_story() -> void:
	var npc := get_parent() as NPC
	if npc == null:
		return
	match response_type:
		Response.NONE:
			state = State.COMPLETE
			_handle_completion()
			return
		Response.DISAPPEAR:
			state = State.COMPLETE
		Response.MOVE:
			if not dir_path.is_empty():
				var vec_path: Array[Vector2] = []
				for dir in dir_path:
					vec_path.append(npc._vector_from_dir(dir))
				await npc.walk_list_dirs(vec_path)
			if end_facing != TileMover.Direction.NONE:
				var end_vec: Vector2 = npc._vector_from_dir(end_facing)
				await npc.start_turning(end_vec)
		Response.BESPOKE:
			pass
	state = State.COMPLETE
	_handle_completion()


func _apply_item_outcome(player: Player) -> void:
	match item_outcome:
		ItemOutcome.NONE:
			pass
		ItemOutcome.GIVE:
			if not item_to_give:
				printerr("NPCBlockerComponent at %s has item_outcome GIVE but no item_to_give" % get_path())
				return
			var ta: Array[String] = ["Please take this %s as a reward!" % item_to_give.name]
			Ui.send_text_box.emit(null, ta, true, false, false)
			await Ui.text_box_complete
			var inv = player.inventory_handler
			inv.remove(item_wanted)
			inv.add(item_to_give)
		ItemOutcome.STORY:
			Global.story_flag_triggered.emit(story_flag, story_value)


func _handle_completion() -> void:
	if state == State.INCOMPLETE:
		return
	var npc := get_parent() as NPC
	match response_type:
		Response.DISAPPEAR:
			if npc:
				npc.visible = false
			if _collision_shape:
				_collision_shape.disabled = true
		Response.MOVE:
			pass
		Response.BESPOKE:
			pass
		Response.NONE:
			pass
