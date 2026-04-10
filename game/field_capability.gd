extends Node

const CLIMBING_SHOES = preload("uid://du7xft6yrfja1")
const SURF = preload("uid://cc3o42tg3cca0")
const CUT = preload("uid://bw063g71xyrx1")
const ROCK_SMASH = preload("uid://bxhxjt62xyrx1")


func get_available_travel_methods() -> Array[Player.TravelState]:
	var travel_methods: Array[Player.TravelState] = []

	if _can_surf():
		travel_methods.append(Player.TravelState.SURFING)

	if _can_climb():
		travel_methods.append(Player.TravelState.CLIMBING)

	return travel_methods


func get_available_removal_methods() -> Array[RemoveBlockerObject.RemovalType]:
	var removal_types: Array[RemoveBlockerObject.RemovalType] = []

	if _can_cut_trees():
		removal_types.append(RemoveBlockerObject.RemovalType.CUT)

	if _can_rock_smash():
		removal_types.append(RemoveBlockerObject.RemovalType.SMASH)

	return removal_types


func _check_monsters_moves(move_ref: Move) -> bool:
	for monster in Player.party.party:
		for move in monster.moves:
			if move == move_ref:
				return true
	return false


func _check_monster_types(type: TypeChart.Type) -> bool:
	for monster in Player.party.party:
		if monster.primary_type == type or monster.secondary_type == type:
			return true
	return false


func _check_items(item_ref: Item) -> bool:
	var inventory = Player.inventory.inventory
	for page: InventoryPage in inventory.values():
		for item: Item in page.page:
			if item == item_ref:
				return true
	return false


func _check_badges(badge: Story.Flag) -> bool:
	return Player.story_flags.story_flags[badge] == true


func _can_surf() -> bool:
	return _check_monsters_moves(SURF) and _check_badges(Story.Flag.BADGE_FOUR)


func _can_climb() -> bool:
	return _check_items(CLIMBING_SHOES)


func _can_cut_trees() -> bool:
	return _check_monsters_moves(CUT) and _check_badges(Story.Flag.BADGE_ONE)


func _can_rock_smash() -> bool:
	return _check_monsters_moves(ROCK_SMASH) and _check_badges(Story.Flag.BADGE_TWO)
