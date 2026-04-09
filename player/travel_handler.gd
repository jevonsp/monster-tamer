extends Node

const CLIMBING_SHOES = preload("uid://du7xft6yrfja1")
const SURF = preload("uid://cc3o42tg3cca0")

@onready var player: Player = $".."


func start_surfing() -> void:
	player.travel_state = Player.TravelState.SURFING
	get_tree().call_group("surf_object", "toggle_mode", TravelBlockerObject.State.PASSABLE)
	await player.walk_one_tile(player.facing_direction)


func stop_surfing() -> void:
	player.travel_state = Player.TravelState.DEFAULT
	get_tree().call_group("surf_object", "toggle_mode", TravelBlockerObject.State.NOT_PASSABLE)


func start_climbing() -> void:
	printerr("IMPLEMENT CLIMBING")


func stop_climbing() -> void:
	printerr("IMPLEMENT CLIMBING")


func get_available_travel_methods() -> Array[Player.TravelState]:
	var travel_methods: Array[Player.TravelState] = [Player.TravelState.DEFAULT]

	if can_surf():
		travel_methods.append(Player.TravelState.SURFING)

	if can_climb():
		travel_methods.append(Player.TravelState.CLIMBING)

	return travel_methods


func get_available_removal_methods() -> Array[RemoveBlockerObject.RemovalType]:
	return [RemoveBlockerObject.RemovalType.CUT, RemoveBlockerObject.RemovalType.SMASH]


func can_surf() -> bool:
	for monster: Monster in Player.party.party:
		for move in monster.moves:
			if move == SURF:
				return true
	return false


func can_climb() -> bool:
	if Player.inventory.has_item(CLIMBING_SHOES):
		return true
	return false
