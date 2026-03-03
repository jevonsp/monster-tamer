extends Node

var party: Array[Monster] = []
var storage: Array[Monster] = []
@onready var player: CharacterBody2D = $".."

func bind_signals() -> void:
	Global.player_party_requested.connect(send_player_party)
	Global.send_monster_death_experience.connect(_grant_party_experience)
	Global.request_switch_creation.connect(_on_request_switch_creation)
	Global.switch_monster_to_first.connect(_on_switch_monster_to_first)
	Global.out_of_battle_switch.connect(_on_out_of_battle_switch)


#region Party Utils
func add(monster: Monster):
	"""Single entry point for adding monsters to the party or storage"""
	if not _add_to_party(monster):
		_add_to_storage(monster)


func _add_to_party(monster: Monster) -> bool:
	"""Adds an existing monster to the party or storage"""
	monster.is_player_monster = true
	if party.size() < 6:
		party.append(monster)
		return true
	else:
		return false
	
	
func _add_to_storage(monster: Monster) -> void:
	storage.append(monster)


func send_player_party() -> void:
	Global.send_player_party.emit(party)
	
	
func _grant_party_experience(amount: int) -> void:
	var getting_exp: Array[Monster]
	for monster in party:
		if monster.was_active_in_battle:
			getting_exp.append(monster)
	for monster in getting_exp:
		await monster.gain_exp(int(amount / float(getting_exp.size())), player.in_battle)
	Global.player_done_giving_exp.emit()
		
		
func fully_heal_and_revive_party() -> void:
	for monster in party:
		monster.fully_heal_and_revive()
		
		
func _on_request_switch_creation(index: int) -> void:
	var switch = Switch.new()
	print("switching in: ", party[index], "name: ", party[index].name)
	switch.actor = party[0]
	switch.target = party[index]
	Global.add_switch_to_turn_queue.emit(switch)
	
	
func _on_switch_monster_to_first(monster: Monster) -> void:
	print("party before:")
	var count = 0
	for m in party:
		print("%s: %s %s" % [count, m.name, m])
		count += 1
		
	var idx = party.find(monster)
	var temp = party[0]
	party[0] = party[idx]
	party[idx] = temp
	
	print("party after:")
	count = 0
	for m in party:
		print("%s: %s %s" % [count, m.name, m])
		count += 1
	
	send_player_party()
	
func _on_out_of_battle_switch(index_one: int, index_two: int) -> void:
	var temp = party[index_one]
	party[index_one] = party[index_two]
	party[index_two] = temp
	
	send_player_party()
#endregion
