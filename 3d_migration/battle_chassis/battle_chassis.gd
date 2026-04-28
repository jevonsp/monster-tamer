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


func is_player_actor(monster: Monster) -> bool:
	return true if monster in player_team else false


func is_enemy_actor(monster: Monster) -> bool:
	return true if monster in enemy_team else false


func resolve_turn() -> void:
	if _turn_index_too_big():
		return
	_set_current_actor()

	for choice: Choice in turn_queue:
		var action_list: ActionList
		match choice.type:
			Choice.Type.MOVE, Choice.Type.ITEM:
				action_list = choice.action.action_list
			Choice.Type.SWITCH, Choice.Type.FLEE:
				action_list = choice.action

		await action_list.run(self)

		turn_index += 1

		if _turn_index_too_big():
			return
		_set_current_actor()


func _set_current_actor() -> void:
	current_actor = turn_queue[turn_index].actor


func _turn_index_too_big() -> bool:
	if turn_index >= turn_queue.size():
		turn_index = 0
		return true
	return false
