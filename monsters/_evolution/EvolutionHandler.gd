extends Node

const EVO_TABLE: EvolutionTable = preload("uid://cbntqm4gc2s7l")

var evolution_table: EvolutionTable = null


func _ready() -> void:
	evolution_table = EVO_TABLE


func check_monster_evolve(monster: Monster, trigger: Entry.Trigger, item: Item = null) -> Entry:
	match trigger:
		Entry.Trigger.LEVEL_UP:
			return check_monster_level_up_evolve(monster)
		Entry.Trigger.ITEM_USE:
			if item:
				return check_monster_item_use_evolve(monster, item)
		Entry.Trigger.TRADE:
			return check_monster_trade_evolve(monster)

	return null


func check_monster_level_up_evolve(monster: Monster) -> Entry:
	var entries = evolution_table.table.get(monster.monster_data)
	if not entries:
		return null

	for entry in entries.list:
		if Entry.check_entry_level_up(monster, entry):
			return entry

	return null


func check_monster_item_use_evolve(monster: Monster, item: Item) -> Entry:
	var entries = evolution_table.table.get(monster.monster_data)
	if not entries:
		return null

	for entry in entries.list:
		if Entry.check_entry_item_use(monster, item, entry):
			return entry

	return null


func check_monster_trade_evolve(monster: Monster) -> Entry:
	var entries = evolution_table.table.get(monster.monster_data)
	if not entries:
		return null

	for entry in entries.list:
		if Entry.check_entry_trade(monster, entry):
			return entry

	return null


func evolve_monster(monster: Monster, entry: Entry) -> Monster:
	var old_monster = {
		name = monster.name,
		nature = monster.nature,
		gender = monster.gender,
		level = monster.level,
		experience = monster.experience,
		moves = monster.moves,
		current_hitpoints = monster.current_hitpoints,
		held_item = monster.held_item,
	}
	var new_monster_data = entry.finish_monster
	var new_monster: Monster = new_monster_data.set_up(old_monster.level)

	new_monster.name = old_monster.name
	new_monster.nature = old_monster.nature
	new_monster.gender = old_monster.gender
	new_monster.experience = old_monster.experience
	new_monster.moves = old_monster.moves.duplicate()
	new_monster.held_item = old_monster.held_item
	new_monster.is_player_monster = true

	new_monster.set_stats()
	new_monster.current_hitpoints = min(old_monster.current_hitpoints, new_monster.max_hitpoints)

	return new_monster
