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
@export_group("Trade (item swap)")
@export var offers_item_trade: bool = false
@export var item_to_take: Item
@export var item_to_give: Item
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
	if state == State.COMPLETE:
		await run_post_complete_interact(player)
		return NPCComponent.Result.TERMINATE
	if offers_item_trade or offers_trade:
		var handled: bool = await try_trade_interact(player)
		if handled:
			return NPCComponent.Result.TERMINATE
		return NPCComponent.Result.CONTINUE
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
	if offers_trade or offers_item_trade:
		await npc._say_dialogue(_format_post_complete_lines(), true, false)
	else:
		await npc._say_dialogue(post_complete_dialogue, true, false)


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


func try_trade_interact(body: CharacterBody2D) -> bool:
	if state == State.COMPLETE:
		return false
	if body is not Player:
		return false
	var player := body as Player
	if offers_item_trade:
		if item_to_give == null:
			return false
		return await _try_item_trade_interact(player)
	if offers_trade:
		if monster_to_take == null or monster_to_give == null:
			return false
		return await _try_monster_trade_interact(player)
	return false


func _try_item_trade_interact(player: Player) -> bool:
	if item_to_take == null:
		var give_only: Array[String] = (
			post_complete_dialogue
			if not post_complete_dialogue.is_empty()
			else ["Please take this %s!" % item_to_give.name]
		)
		Ui.send_text_box.emit(null, give_only, true, false, false)
		await Ui.text_box_complete
		player.inventory_handler.add(item_to_give)
		state = State.COMPLETE
		Global.toggle_player.emit()
		return true
	var inventory := player.inventory_handler.inventory as Dictionary[Item.Type, InventoryPage]
	var found: Item = null
	for inv_page: InventoryPage in inventory.values():
		for item: Item in inv_page.page:
			if item == item_to_take:
				found = item
				break
		if found:
			break
	if found == null:
		var fail: Array[String] = ["You don't have the %s I need." % item_to_take.name]
		Ui.send_text_box.emit(null, fail, true, false, false)
		await Ui.text_box_complete
		Global.toggle_player.emit()
		return true
	var intro: Array[String] = ["Perfect! You have the %s I wanted." % item_to_take.name]
	Ui.send_text_box.emit(null, intro, true, false, false)
	await Ui.text_box_complete
	var ask: Array[String] = ["Trade it for my %s?" % item_to_give.name]
	Ui.send_text_box.emit(null, ask, false, true, false)
	var answer: bool = await Ui.answer_given
	await Ui.text_box_complete
	if answer:
		player.inventory_handler.remove(item_to_take)
		player.inventory_handler.add(item_to_give)
		var bye: Array[String] = ["Pleasure doing business!"]
		Ui.send_text_box.emit(null, bye, true, false, false)
		await Ui.text_box_complete
		state = State.COMPLETE
		Global.toggle_player.emit()
		return true
	var reject: Array[String] = ["Maybe another time."]
	Ui.send_text_box.emit(null, reject, true, false, false)
	await Ui.text_box_complete
	Global.toggle_player.emit()
	return true


func _try_monster_trade_interact(player: Player) -> bool:
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
	Ui.send_text_box.emit(null, intro, true, false, false)
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
		Ui.send_text_box.emit(null, bye, true, false, false)
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
	var give_name := ""
	if offers_item_trade:
		if item_to_take:
			take_name = item_to_take.name
		if item_to_give:
			give_name = item_to_give.name
	else:
		if monster_to_take:
			take_name = monster_to_take.species
		if monster_to_give:
			give_name = monster_to_give.species
	var out: Array[String] = []
	for line in post_complete_dialogue:
		out.append(
			line.format({
				"take": take_name,
				"give": give_name,
				"item": take_name if take_name != "" else give_name,
			})
		)
	return out
