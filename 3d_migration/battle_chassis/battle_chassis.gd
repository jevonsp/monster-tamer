class_name BattleChassis
extends Resource

@export var player_team: Array[Monster] = []
@export var enemy_team: Array[Monster] = []
@export var player_actors: Dictionary[int, Monster] = { }
@export var enemy_actors: Dictionary[int, Monster] = { }

var turn_queue: Array[Choice] = []
var turn_index: int = 0
var current_actor: Monster
var trainer: Trainer3D
var targeter: Targeter


func create_helpers() -> void:
	targeter = Targeter.new()


func is_player_actor(monster: Monster) -> bool:
	return true if monster in player_team else false


func is_enemy_actor(monster: Monster) -> bool:
	return true if monster in enemy_team else false
