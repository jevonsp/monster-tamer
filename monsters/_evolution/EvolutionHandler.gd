extends Node

signal evolution_screen_requested(monster: Monster, entry: Entry)
signal evolution_process_finished
signal evolution_result(result: Result)

enum Result { COMPLETE, CANCEL }

const EVO_TABLE: EvolutionTable = preload("uid://cbntqm4gc2s7l")

var evolution_table: EvolutionTable = null


func _ready() -> void:
	evolution_table = EVO_TABLE


func check_monster_evolve(monster: Monster, trigger: Entry.Trigger, item: Item = null) -> Entry:
	match trigger:
		Entry.Trigger.LEVEL_UP:
			return check_monster_level_up_evolve(monster)
		Entry.Trigger.ITEM_USE:
			if item != null:
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


func evolve_monster_in_place(monster: Monster, entry: Entry) -> void:
	var starting_name: Variant = monster.name
	var has_nickname: bool = starting_name != monster.monster_data.species

	if not has_nickname:
		starting_name = null

	monster.monster_data = entry.finish_monster

	monster.set_stats()
	monster.set_type()
	monster.set_monster_name(has_nickname, starting_name)

	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if player:
		player.party_handler.send_player_party()
	Global.request_display_monsters.emit()


func request_evolve(monster: Monster, entry: Entry) -> void:
	evolution_screen_requested.emit(monster, entry)

	var result = await evolution_result

	match result:
		Result.COMPLETE:
			evolve_monster_in_place(monster, entry)
		Result.CANCEL:
			pass


func finish_evolve() -> void:
	evolution_process_finished.emit()
