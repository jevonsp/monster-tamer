extends Node

const CUT = preload("uid://dct4aev5dipxt")
const ROCK_SMASH = preload("uid://dsnxexesn8m00")
const SURF = preload("uid://bretmrdrou0vg")
const CLIMBING_SHOES = preload("uid://xonkjuu2u8sm")


func get_available_travel_methods() -> Array[TravelHandler3D.TravelState]:
	var travel_methods: Array[TravelHandler3D.TravelState] = []

	if _can_surf():
		travel_methods.append(TravelHandler3D.TravelState.SURFING)

	return travel_methods


func get_available_removal_methods() -> Array[ProgressBlockerObject.RemovalType]:
	var removal_types: Array[ProgressBlockerObject.RemovalType] = []

	if _can_cut_trees():
		removal_types.append(ProgressBlockerObject.RemovalType.CUT)

	if _can_rock_smash():
		removal_types.append(ProgressBlockerObject.RemovalType.SMASH)

	return removal_types


func _check_monsters_moves(move_ref: Move) -> bool:
	# This basically has all the possible checks i could ever want lol
	if PlayerContext3D.party_handler.party.is_empty():
		return false

	for monster in PlayerContext3D.party_handler.party:
		for move in monster.monster_data.learn_set:
			if move == move_ref:
				return true
		for move in monster.monster_data.level_up_moves:
			if monster.monster_data.level_up_moves[move] == move_ref:
				return true
		for move in monster.monster_data.starting_moves:
			if move == move_ref:
				return true
		for move in monster.moves:
			if move == move_ref:
				return true
	return false


func _check_monster_types(type: TypeChart.Type) -> bool:
	for monster in PlayerContext3D.party_handler.party:
		if monster.primary_type == type or monster.secondary_type == type:
			return true
	return false


func _check_items(item_ref: Item) -> bool:
	var inventory = PlayerContext3D.inventory_handler.inventory
	for page: InventoryPage in inventory.values():
		for item: Item in page.page:
			if item == item_ref:
				return true
	return false


func _check_badges(badge: Story.Flag) -> bool:
	return PlayerContext3D.story_flag_handler.story_flags[badge] == true


func _can_surf() -> bool:
	return _check_monsters_moves(SURF) and _check_badges(Story.Flag.BADGE_THREE)


func _can_climb() -> bool:
	return _check_items(CLIMBING_SHOES)


func _can_cut_trees() -> bool:
	return _check_monsters_moves(CUT) and _check_badges(Story.Flag.BADGE_ONE)


func _can_rock_smash() -> bool:
	return _check_monsters_moves(ROCK_SMASH) and _check_badges(Story.Flag.BADGE_TWO)
