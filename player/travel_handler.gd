extends Node

const CLIMBING_SHOES = preload("uid://du7xft6yrfja1")
const SURF = preload("uid://cc3o42tg3cca0")
const CUT = preload("res://moves/cut/cut.tres")
const ROCK_SMASH = preload("res://moves/rock_smash/rock_smash.tres")

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

	if _party_has_move(SURF):
		travel_methods.append(Player.TravelState.SURFING)

	if _party_has_item(CLIMBING_SHOES):
		travel_methods.append(Player.TravelState.CLIMBING)

	return travel_methods


func get_available_removal_methods() -> Array[RemoveBlockerObject.RemovalType]:
	var removal_methods: Array[RemoveBlockerObject.RemovalType] = []

	if _party_has_move(CUT):
		removal_methods.append(RemoveBlockerObject.RemovalType.CUT)

	if _party_has_move(ROCK_SMASH):
		removal_methods.append(RemoveBlockerObject.RemovalType.SMASH)

	return [RemoveBlockerObject.RemovalType.CUT, RemoveBlockerObject.RemovalType.SMASH]


func _party_has_move(move_res: Move) -> bool:
	for monster: Monster in Player.party.party:
		for m in monster.moves:
			if m == move_res:
				return true
	return false


func _party_has_item(item: Item) -> bool:
	if Player.inventory.has_item(item):
		return true
	return false
