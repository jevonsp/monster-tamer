class_name NuzlockeTracker
extends Resource

@export var route_tracker: Dictionary = { }


func create_route_tracker() -> void:
	route_tracker.clear()
	for val in Map.Location.values():
		route_tracker[val] = false


func hydrate_from_save(raw: Variant) -> void:
	if typeof(raw) != TYPE_DICTIONARY:
		create_route_tracker()
		return
	var d: Dictionary = raw
	if d.is_empty():
		create_route_tracker()
		return
	for val in Map.Location.values():
		if not d.has(val):
			d[val] = false
	route_tracker = d


func monster_encountered_on_route(location: Map.Location) -> void:
	route_tracker[location] = true


func can_catch_monster_on_route(location: Map.Location) -> bool:
	var options: Resource = PlayerContext3D.player_info_handler.game_options
	if options != null and options.game_variant == 1:
		return not route_tracker.get(location, false)
	return true
