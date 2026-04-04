class_name NPCStoreComponent
extends NPCComponent

@export var inventory: Dictionary[Item.Type, InventoryPage] = { }


func trigger(obj: Node) -> NPCComponent.Result:
	if obj.is_in_group("player"):
		_open_store()
	return NPCComponent.Result.CONTINUE


func on_save_game(saved_data_array: Array[SavedData]) -> void:
	var new_saved_data = SavedData.new()

	new_saved_data.node_path = get_path()
	new_saved_data.inventory = inventory

	saved_data_array.append(new_saved_data)


func on_load_game(saved_data_array: Array[SavedData]) -> void:
	for data: SavedData in saved_data_array:
		if data.node_path == get_path():
			inventory = data.inventory


func _open_store() -> void:
	if inventory.size() <= 1:
		printerr("%s has no inventory to display" % self)
		return
	Global.toggle_player.emit()
	Ui.request_open_store.emit(self)
