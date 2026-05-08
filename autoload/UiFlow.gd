extends Node

signal world_input_block_state_changed(is_blocked: bool)

var _entries: Dictionary = { }
var _order_counter: int = 0
var _last_blocked: bool = false


func register_ui_layer(
		source: Object,
		blocks_world_input: bool = true,
		priority: int = 0,
) -> void:
	if source == null:
		return
	var id := source.get_instance_id()
	var entry: Dictionary = _entries.get(id, { })
	if entry.is_empty():
		entry["source"] = source
		entry["order"] = _order_counter
		_order_counter += 1
	entry["blocks_world_input"] = blocks_world_input
	entry["priority"] = priority
	_entries[id] = entry
	_emit_if_block_state_changed()


func unregister_ui_layer(source: Object) -> void:
	if source == null:
		return
	var id := source.get_instance_id()
	if _entries.erase(id):
		_emit_if_block_state_changed()


func is_world_input_blocked() -> bool:
	_prune_invalid_entries()
	for entry in _entries.values():
		if entry.get("blocks_world_input", false):
			return true
	return false


func get_top_ui_layer() -> Object:
	_prune_invalid_entries()
	var best_source: Object = null
	var best_priority := -INF
	var best_order := -INF
	for entry in _entries.values():
		var source: Object = entry.get("source")
		if source == null:
			continue
		var priority: int = int(entry.get("priority", 0))
		var order: int = int(entry.get("order", 0))
		if priority > best_priority or (priority == best_priority and order > best_order):
			best_priority = priority
			best_order = order
			best_source = source
	return best_source


func _prune_invalid_entries() -> void:
	var ids_to_erase: Array[int] = []
	for id in _entries.keys():
		var source: Object = _entries[id].get("source")
		if source == null or not is_instance_valid(source):
			ids_to_erase.append(id)
	for id in ids_to_erase:
		_entries.erase(id)


func _emit_if_block_state_changed() -> void:
	var blocked := is_world_input_blocked()
	if blocked == _last_blocked:
		return
	_last_blocked = blocked
	world_input_block_state_changed.emit(blocked)
