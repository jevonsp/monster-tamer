extends Node

var party: Array[Monster] = []
var storage: Array[Monster] = []
@onready var player: CharacterBody2D = $".."

func bind_signals() -> void:
	Global.player_party_requested.connect(send_player_party)
	Global.send_monster_death_experience.connect(_grant_party_experience)

#region Party Utils
func add(monster: Monster):
	"""Single entry point for adding monsters to the party or storage"""
	if not _add_to_party(monster):
		_add_to_storage(monster)

func _add_to_party(monster: Monster) -> bool:
	"""Adds an existing monster to the party or storage"""
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
		if monster.was_in_battle:
			getting_exp.append(monster)
	for monster in getting_exp:
		await monster.gain_exp(int(amount / float(getting_exp.size())), player.in_battle)
	Global.player_done_giving_exp.emit()
		
func heal_party() -> void:
	for monster in party:
		monster.heal(false)
		
func heal_and_revive_party() -> void:
	for monster in party:
		monster.heal(true)
#endregion
