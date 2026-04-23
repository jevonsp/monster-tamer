class_name PartyHandler3D
extends Node

const MAX_PARTY_SIZE := 6
const STORAGE_SIZE := 300

var party: Array[Monster] = []
var storage: Dictionary[int, Monster] = { }

@onready var player: Player3D = $".."


func create_storage() -> void:
	for i in range(STORAGE_SIZE):
		storage[i] = null


func send_player_party() -> void:
	Party.send_player_party.emit(party)


func send_player_storage() -> void:
	Party.send_player_storage.emit(storage)


func send_player_party_and_storage() -> void:
	Party.send_player_party_and_storage.emit(party, storage)


func add(monster: Monster):
	if not _add_to_party(monster):
		_add_to_storage(monster)

	send_player_party_and_storage()


func fully_heal_and_revive_party() -> void:
	for monster: Monster in party:
		if Options.is_nuzlocke() and monster.is_disabled:
			continue
		monster.fully_heal_and_revive()
		monster.restore_pp()
	send_player_party()


func can_deposit_from_party() -> bool:
	return party.size() > 1


func can_release_monster(monster: Monster) -> bool:
	if party.size() == 1 and party.has(monster):
		return false
	return true


func remove_monster(monster: Monster, with_farewell: bool = true) -> void:
	if not party.has(monster) and storage.find_key(monster) == null:
		return

	if with_farewell:
		var ta: Array[String] = ["Goodbye %s, I'll miss you!" % [monster.name]]
		Ui.send_text_box.emit(null, ta, true, false, false)
		await Ui.text_box_complete

	if party.has(monster):
		party.erase(monster)
	var storage_idx: Variant = storage.find_key(monster)
	if storage_idx != null:
		storage[storage_idx] = null

	send_player_party_and_storage()


func deposit_monster(monster: Monster) -> void:
	var idx = party.find(monster)
	if idx < 0:
		return
	party.erase(monster)
	_add_to_storage(monster)
	send_player_party_and_storage()


func withdraw_monster(monster: Monster) -> void:
	var val = storage.find_key(monster)
	if val == null:
		return
	storage[val] = null
	_add_to_party(monster)
	send_player_party_and_storage()


func on_switch_moves(monster: Monster, index_one: int, index_two: int) -> void:
	if index_one == -1 or index_two == -1:
		return
	var temp = monster.moves[index_one]
	monster.moves[index_one] = monster.moves[index_two]
	monster.moves[index_two] = temp
	send_player_party()


func _connect_signals() -> void:
	Party.capture_monster.connect(add)
	Party.player_party_requested.connect(send_player_party)
	Battle.send_monster_death_experience.connect(_grant_party_experience)
	Ui.request_switch_creation.connect(_on_request_switch_creation)
	Battle.switch_monster_to_first.connect(_on_switch_monster_to_first)
	Party.out_of_battle_switch.connect(_on_out_of_battle_switch)
	Party.storage_deposit_monster.connect(deposit_monster)
	Party.storage_withdraw_monster.connect(withdraw_monster)
	Party.request_move_party_to_storage.connect(_move_party_to_storage)
	Party.request_move_storage_to_party.connect(_move_storage_to_party)
	Party.request_switch_moves.connect(on_switch_moves)


func _add_to_party(monster: Monster) -> bool:
	monster.is_player_monster = true
	if party.size() < MAX_PARTY_SIZE:
		party.append(monster)
		return true
	else:
		return false


func _add_to_storage(monster: Monster, index: int = -1) -> void:
	if index == -1:
		for key in storage:
			if storage[key] == null:
				storage[key] = monster
				break
	else:
		storage[index] = monster


func _move_party_to_storage(from_index: int, to_index: int) -> void:
	var temp = storage[to_index]
	storage[to_index] = party[from_index]
	if temp != null:
		party[from_index] = temp
	else:
		party.erase(party[from_index])
	send_player_party_and_storage()


func _move_storage_to_party(from_index: int, to_index: int) -> void:
	if to_index >= party.size():
		withdraw_monster(storage[from_index])
	else:
		var temp = party[to_index]
		party[to_index] = storage[from_index]
		storage[from_index] = temp
	send_player_party_and_storage()


func _grant_party_experience(amount: int) -> void:
	var getting_exp: Array[Monster] = []
	for monster in party:
		if monster.was_active_in_battle:
			getting_exp.append(monster)
	if getting_exp.is_empty():
		Battle.player_done_giving_exp.emit()
		return
	var share := int(amount / float(getting_exp.size()))
	for monster in getting_exp:
		await monster.gain_exp(share, player.in_battle)
	Battle.player_done_giving_exp.emit()


func _on_request_switch_creation(index: int) -> void:
	var switch = Switch.new()
	switch.actor = party[0]
	switch.target = party[index]
	Battle.add_switch_to_turn_queue.emit(switch)


func _on_switch_monster_to_first(monster: Monster) -> void:
	var idx = party.find(monster)
	var temp = party[0]
	party[0] = party[idx]
	party[idx] = temp

	send_player_party()


func _on_out_of_battle_switch(index_one: int, index_two: int) -> void:
	var temp = party[index_one]
	party[index_one] = party[index_two]
	party[index_two] = temp

	send_player_party()
