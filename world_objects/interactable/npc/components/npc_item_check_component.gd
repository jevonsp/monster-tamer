extends NPCComponent

enum Result { NONE, GIVE, STORY }

@export var item_wanted: Item
@export var result_type: Result = Result.NONE
@export var item_to_give: Item = null
@export var story_flag: Story.Flag = Story.Flag.NONE
@export var story_value: bool = true


func trigger(obj: Node) -> void:
	if obj is not Player:
		return
	if not item_wanted:
		return

	var player = obj as Player
	var inventory = player.inventory_handler.inventory as Dictionary[Item.Type, InventoryPage]

	var ta: Array[String]

	for inv_page: InventoryPage in inventory.values():
		for item: Item in inv_page.page:
			if item == item_wanted:
				ta = ["Perfect! I've been looking for that %s." % item_wanted.name]
				Ui.send_text_box.emit(null, ta, false, false, false)
				await Ui.text_box_complete
				await action()
				Global.toggle_player.emit()
				return

	ta = ["You don't have the %s I want.." % item_wanted.name]
	Ui.send_text_box.emit(null, ta, false, false, false)
	await Ui.text_box_complete
	Global.toggle_player.emit()


func action() -> void:
	match result_type:
		Result.NONE:
			pass
		Result.GIVE:
			if not item_to_give:
				printerr("NPC %s at %s has no item to give" % [self, get_path()])
				return
			var ta: Array[String] = ["Please take this %s as a reward!" % item_to_give.name]

			Ui.send_text_box.emit(null, ta, false, false, false)
			await Ui.text_box_complete

			var player = get_tree().get_first_node_in_group("player")
			var inventory = player.inventory_handler

			inventory.remove(item_wanted)
			inventory.add(item_to_give)
		Result.STORY:
			Global.story_flag_triggered.emit(story_flag, story_value)
