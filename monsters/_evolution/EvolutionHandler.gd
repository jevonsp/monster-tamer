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
	return monster
