class_name BattleSession
extends Node

var player_actor: Monster
var enemy_actor: Monster
var player_party: Array[Monster] = []
var is_wild_battle: bool = true
var enemy_trainer: Trainer = null
var enemy_party: Array[Monster] = []


func set_player_actor(monster: Monster) -> void:
	player_actor = monster
	if player_actor:
		player_actor.was_active_in_battle = true


func set_enemy_actor(monster: Monster) -> void:
	enemy_actor = monster


func switch_actors(old: Monster, new: Monster) -> void:
	if old == player_actor:
		player_actor = new
		if player_actor:
			player_actor.was_active_in_battle = true
	elif old == enemy_actor:
		enemy_actor = new


func set_player_party(party: Array[Monster]) -> void:
	player_party = party


func start_wild_battle(monster_data: MonsterData, level: int) -> void:
	clear_actors()
	var monster: Monster = monster_data.set_up(level)
	enemy_party = [monster]
	set_enemy_actor(enemy_party[0])
	set_player_actor(player_party[0])


func start_trainer_battle(trainer: Trainer) -> void:
	clear_actors()
	is_wild_battle = false
	enemy_trainer = trainer
	_set_enemy_party(trainer.party, trainer.party_levels)
	set_enemy_actor(enemy_party[0])
	set_player_actor(player_party[0])


func _set_enemy_party(party: Array[MonsterData], levels: Array[int]) -> void:
	enemy_party.clear()
	for i in range(len(party)):
		var monster: Monster = party[i].set_up(levels[i])
		enemy_party.append(monster)


func reset_stats() -> void:
	for monster: Monster in enemy_party:
		for stat in monster.stat_stages_and_multis.stat_stages.keys():
			monster.stat_stages_and_multis.stat_stages[stat] = 0
		for stat in monster.stat_stages_and_multis.stat_multipliers.keys():
			monster.stat_stages_and_multis.stat_multipliers[stat] = 1.0
	for monster: Monster in player_party:
		for stat in monster.stat_stages_and_multis.stat_stages.keys():
			monster.stat_stages_and_multis.stat_stages[stat] = 0
		for stat in monster.stat_stages_and_multis.stat_multipliers.keys():
			monster.stat_stages_and_multis.stat_multipliers[stat] = 1.0


func clear_actors() -> void:
	player_actor = null
	enemy_actor = null


func clear_parties() -> void:
	enemy_trainer = null
	player_party = []
	enemy_party = []


func clear_all_battle_state() -> void:
	reset_stats()
	clear_actors()
	clear_parties()
	is_wild_battle = true
