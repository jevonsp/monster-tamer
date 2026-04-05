extends Node

func can_use_outside_battle(item: Item) -> bool:
	return item.use_effect != null


func can_give_to_monster(item: Item) -> bool:
	if item.catch_effect != null:
		return false
	if item.use_effect != null:
		return false
	return item.held_effect != null


func can_use_in_battle(item: Item) -> bool:
	return item.use_effect != null or item.catch_effect != null


func battle_item_blocked_reason(item: Item, is_trainer_battle: bool) -> String:
	if not can_use_in_battle(item):
		return "cant_use"
	if is_trainer_battle and item.catch_effect:
		return "trainer_catch"
	return ""


func give_item_to_monster(item: Item, monster: Monster, text_box_sender: Node) -> void:
	if monster == null:
		return

	if monster.hold_item(item):
		Inventory.give_item_to.emit(item, monster)
		await _show_item_given_text(item, monster, text_box_sender)
		return

	if not await _confirm_item_swap(monster, text_box_sender):
		return

	monster.swap_items(item)
	Inventory.give_item_to.emit(item, monster)
	await _show_item_given_text(item, monster, text_box_sender)


func use_item_on_monster_after_party_pick(item: Item, monster: Monster) -> void:
	var entry = EvolutionHandler.check_monster_evolve(monster, Entry.Trigger.ITEM_USE, item)
	if entry:
		EvolutionHandler.request_evolve(monster, entry)
		await EvolutionHandler.evolution_process_finished
		return

	Inventory.use_item_on.emit(item, monster)
	await Ui.item_finished_using


func _show_item_given_text(item: Item, monster: Monster, text_box_sender: Node) -> void:
	var ta: Array[String] = ["Gave %s to %s to hold." % [item.name, monster.name]]
	Ui.send_text_box.emit(text_box_sender, ta, false, false, false)
	await Ui.text_box_complete


func _confirm_item_swap(monster: Monster, text_box_sender: Node) -> bool:
	var held_item_name: String = monster.held_item.name if monster.held_item != null else "that item"
	var ta: Array[String] = ["%s is already holding %s. Swap items?" % [monster.name, held_item_name]]
	Ui.send_text_box.emit(text_box_sender, ta, false, true, false)
	var should_swap: bool = await Ui.answer_given
	await Ui.text_box_complete
	return should_swap
