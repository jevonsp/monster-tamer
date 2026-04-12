class_name NuzlockeTracker
extends Node

static var route_tracker: Dictionary = { }


static func create_route_tracker() -> void:
	route_tracker.clear()
	for val in Map.Location.values():
		route_tracker[val] = false

	Player.info.nuzlocke_tracker = route_tracker


static func hydrate_from_save(info: Info) -> void:
	if not info.player_info.has("nuzlocke_tracker"):
		create_route_tracker()
		return
	var raw: Variant = info.player_info["nuzlocke_tracker"]
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
	info.nuzlocke_tracker = d
	route_tracker = d


static func monster_caught_on_route(location: Map.Location) -> void:
	route_tracker[location] = true


static func can_catch_monster_on_route(location: Map.Location) -> bool:
	if Options.game_variant == Options.GameVariant.NUZLOCKE:
		return not route_tracker.get(location, false)
	return true
