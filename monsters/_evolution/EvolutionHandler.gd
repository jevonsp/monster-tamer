extends Node

const EVO_TABLE: EvolutionTable = preload("uid://cbntqm4gc2s7l")

var evo_table: EvolutionTable = null


func _ready() -> void:
	evo_table = EVO_TABLE


func check_monster_evolve(monster: Monster, trigger: Entry.Trigger, item: Item = null) -> bool:
	match trigger:
		Entry.Trigger.LEVEL_UP:
			return check_monster_level_up_evolve(monster)
		Entry.Trigger.ITEM_USE:
			if item:
				return check_monster_item_use_evolve(monster, item)
		Entry.Trigger.TRADE:
			return check_monster_trade_evolve(monster)

	return false


func check_monster_level_up_evolve(monster: Monster) -> bool:
	var entries = evo_table.evolution_table.get(monster.monster_data)
	if not entries:
		return false

	for entry in entries.list:
		if Entry.check_entry_level_up(monster, entry):
			return true

	return false


func check_monster_item_use_evolve(monster: Monster, item: Item) -> bool:
	var entries = evo_table.evolution_table.get(monster.monster_data)
	if not entries:
		return false

	for entry in entries.list:
		if Entry.check_entry_item_use(item, entry):
			return true

	return false


func check_monster_trade_evolve(monster: Monster) -> bool:
	var entries = evo_table.evolution_table.get(monster.monster_data)
	if not entries:
		return false

	for entry in entries.list:
		if Entry.check_entry_trade(monster, entry):
			return true

	return false
