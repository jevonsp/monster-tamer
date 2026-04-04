class_name NPCServiceComponent
extends NPCComponent

enum State { INCOMPLETE, COMPLETE }

@export var state: State = State.INCOMPLETE
@export_group("Respawn")
@export var offers_respawn: bool = true
@export_group("Heal")
@export var offers_heal: bool = true
@export_multiline var heal_acknowledgement: Array[String] = ["Your party has been healed back to full."]
@export_group("Teleport")
@export var offers_teleport: bool = false
@export var teleport_destination: Node2D
@export_group("Trade (monster swap)")
@export var offers_trade: bool = false
@export var monster_to_take: MonsterData
@export var monster_to_give: MonsterData
@export_group("Post-complete")
@export_multiline var post_complete_dialogue: Array[String] = []


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("save_object")


func trigger(obj: Node) -> NPCComponent.Result:
	if not obj.is_in_group("player"):
		return NPCComponent.Result.CONTINUE
	var player := obj as Player
	if offers_respawn and player.has_method("set_respawn_point"):
		player.set_respawn_point()
	if offers_heal:
		player.party_handler.fully_heal_and_revive_party()
		if not heal_acknowledgement.is_empty():
			Ui.send_text_box.emit(null, heal_acknowledgement, true, false, false)
			await Ui.text_box_complete
	if offers_teleport and teleport_destination != null:
		player.global_position = teleport_destination.global_position
	return NPCComponent.Result.CONTINUE


func run_post_complete_interact(body: CharacterBody2D) -> void:
	var npc := get_parent() as NPC
	if npc == null:
		return
	var toward_player: Vector2 = npc._get_step_direction_to(body.global_position)
	if toward_player != Vector2.ZERO and toward_player != npc.facing_vec:
		await npc.start_turning(toward_player)
	if post_complete_dialogue.is_empty():
		return
	if offers_trade:
		await npc._say_dialogue(_format_post_complete_lines(), false, false)
	else:
		await npc._say_dialogue(post_complete_dialogue, false, false)


func on_save_game(saved_data_array: Array[SavedData]) -> void:
	var new_saved_data := SavedData.new()
	new_saved_data.node_path = get_path()
	new_saved_data.state = state as int
	saved_data_array.append(new_saved_data)


func on_load_game(saved_data_array: Array[SavedData]) -> void:
	if not is_node_ready():
		await ready
	for data: SavedData in saved_data_array:
		if data.node_path == get_path():
			state = data.state as State


## Same idea as [method NPCBlockerComponent.try_item_interact]: runs before dialogue; returns true if handled.
func try_trade_interact(body: CharacterBody2D) -> bool:
	if not offers_trade:
		return false
	if state == State.COMPLETE:
		return false
	if monster_to_take == null or monster_to_give == null:
		return false
	if body is not Player:
		return false
	var player := body as Player
	var party: Array[Monster] = player.party_handler.party
	var monster_in_party: Monster = null
	for monster: Monster in party:
		if monster.monster_data == monster_to_take:
			monster_in_party = monster
			break
	if monster_in_party == null:
		var fail: Array[String] = [
			"You dont have the %s I'm looking for. Come back when you have it!" % monster_to_take.species,
		]
		Ui.send_text_box.emit(null, fail, true, false, false)
		await Ui.text_box_complete
		Global.toggle_player.emit()
		return true
	var intro: Array[String] = ["Perfect! You have a %s I'm looking for." % monster_to_take.species]
	Ui.send_text_box.emit(null, intro, false, false, false)
	await Ui.text_box_complete
	var ask: Array[String] = ["Would you like to trade it for my %s?" % monster_to_give.species]
	Ui.send_text_box.emit(null, ask, false, true, false)
	var answer: bool = await Ui.answer_given
	await Ui.text_box_complete
	if answer:
		party.erase(monster_in_party)
		var received: Monster = monster_to_give.set_up(monster_in_party.level)
		player.party_handler.add(received)
		var bye: Array[String] = [
			"Bye %s! I'll take good care of %s." % [monster_to_give.species, monster_to_take.species],
		]
		Ui.send_text_box.emit(null, bye, false, false, false)
		await Ui.text_box_complete
		state = State.COMPLETE
		Global.toggle_player.emit()
		return true
	var reject: Array[String] = ["That's too bad. I want that %s!" % monster_to_take.species]
	Ui.send_text_box.emit(null, reject, true, false, false)
	await Ui.text_box_complete
	Global.toggle_player.emit()
	return true


func _format_post_complete_lines() -> Array[String]:
	var take_name := ""
	if monster_to_take:
		take_name = monster_to_take.species
	var give_name := ""
	if monster_to_give:
		give_name = monster_to_give.species
	var out: Array[String] = []
	for line in post_complete_dialogue:
		out.append(line.format({ "take": take_name, "give": give_name }))
	return out
