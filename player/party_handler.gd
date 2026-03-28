extends Node

const MAX_PARTY_SIZE := 6
const STORAGE_SIZE := 300

var party: Array[Monster] = []
var storage: Dictionary[int, Monster] = { }

@onready var player: CharacterBody2D = $".."


func bind_signals() -> void:
	Global.capture_monster.connect(add)
	Global.player_party_requested.connect(send_player_party)
	Global.send_monster_death_experience.connect(_grant_party_experience)
	Global.request_switch_creation.connect(_on_request_switch_creation)
	Global.switch_monster_to_first.connect(_on_switch_monster_to_first)
	Global.out_of_battle_switch.connect(_on_out_of_battle_switch)
	Global.storage_deposit_monster.connect(_deposit_monster)
	Global.storage_withdraw_monster.connect(_withdraw_monster)
	Global.request_move_party_to_storage.connect(_move_party_to_storage)
	Global.request_move_storage_to_party.connect(_move_storage_to_party)
	Global.request_switch_moves.connect(_on_switch_moves)


func create_storage() -> void:
	for i in range(STORAGE_SIZE):
		storage[i] = null


func send_player_party() -> void:
	Global.send_player_party.emit(party)


func send_player_storage() -> void:
	Global.send_player_storage.emit(storage)


func send_player_party_and_storage() -> void:
	Global.send_player_party_and_storage.emit(party, storage)


func add(monster: Monster):
	"""Single entry point for adding new monsters to the party or storage"""
	if not _add_to_party(monster):
		_add_to_storage(monster)

	send_player_party_and_storage()


func fully_heal_and_revive_party() -> void:
	for monster in party:
		monster.fully_heal_and_revive()
	send_player_party()


func remove_monster(monster: Monster) -> void:
	if not party.has(monster) or not storage.has(monster):
		return

	var ta: Array[String] = ["Goodbye %s, I'll miss you!" % [monster.name]]
	Global.send_text_box.emit(null, ta, true, false, false)
	await Global.text_box_complete

	if party.has(monster):
		party.erase(monster)
	if storage.has(monster):
		var idx = storage.find_key(monster)
		if idx:
			storage[idx] = null

	send_player_party_and_storage()


func evolve_monster(monster: Monster, entry: Entry) -> void:
	if monster not in party:
		return

	var idx = party.find(monster)
	var new_monster = EvolutionHandler.evolve_monster(monster, entry)

	party[idx] = new_monster

	send_player_party()


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


func _deposit_monster(monster: Monster) -> void:
	"""Only use on monsters in party"""
	var idx = party.find(monster)
	if idx < 0:
		return
	party.erase(monster)
	_add_to_storage(monster)
	send_player_party_and_storage()


func _withdraw_monster(monster: Monster) -> void:
	"""Only use on monsters in storage"""
	var val = storage.find_key(monster)
	if val == null:
		return
	storage[val] = null
	_add_to_party(monster)
	send_player_party_and_storage()


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
		_withdraw_monster(storage[from_index])
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
		Global.player_done_giving_exp.emit()
		return
	var share := int(amount / float(getting_exp.size()))
	for monster in getting_exp:
		await monster.gain_exp(share, player.in_battle)
	Global.player_done_giving_exp.emit()


func _on_request_switch_creation(index: int) -> void:
	var switch = Switch.new()
	switch.actor = party[0]
	switch.target = party[index]
	Global.add_switch_to_turn_queue.emit(switch)


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


func _on_switch_moves(monster: Monster, index_one: int, index_two: int) -> void:
	if index_one == -1 or index_two == -1:
		return
	var temp = monster.moves[index_one]
	monster.moves[index_one] = monster.moves[index_two]
	monster.moves[index_two] = temp
	send_player_party()
