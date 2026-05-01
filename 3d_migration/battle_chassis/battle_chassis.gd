class_name BattleChassis
extends Resource

signal actors_changed(p_actors: Dictionary[int, Monster], e_actors: Dictionary[int, Monster])

@export var player_team: Array[Monster] = []
@export var enemy_team: Array[Monster] = []
@export var player_actors: Dictionary[int, Monster] = { }
@export var enemy_actors: Dictionary[int, Monster] = { }

var turn_queue: Array[Choice] = []
var turn_index: int = 0
var current_actor: Monster
var trainer: Trainer3D
var _processing_turn: bool = false


func _init() -> void:
	if not Battle.wild_battle_requested.is_connected(_create_wild_battle):
		Battle.wild_battle_requested.connect(_create_wild_battle)


func resolve_turn(presenter: BattlePresenter) -> void:
	if _turn_index_too_big():
		return

	_processing_turn = true

	for choice: Choice in turn_queue:
		_set_current_actor()
		var action_list := _resolve_action_list(choice)
		if action_list == null:
			turn_index += 1
			if _turn_index_too_big():
				return
			continue

		var ctx := ActionContext.new(self, choice, presenter)
		await action_list.run(ctx)

		turn_index += 1
		if _turn_index_too_big():
			return

	_clean_up_turn()

	_processing_turn = false


func advance_turn() -> void:
	create_and_enqueue_enemy_action()
	resolve_turn(Battle.presenter)


func create_and_enqueue_enemy_action() -> void:
	pass


func is_player_actor(monster: Monster) -> bool:
	return true if monster in player_team else false


func is_enemy_actor(monster: Monster) -> bool:
	return true if monster in enemy_team else false


func change_actor(
		team: Dictionary[int, Monster],
		out_monster: Monster,
		in_monster: Monster,
) -> bool:
	var out_key: int = team.find_key(out_monster)
	if out_key:
		team[out_key] = in_monster
		actors_changed.emit(player_actors, enemy_actors)
		return true
	return false


func is_processing_turn():
	return _processing_turn


func _clean_up_turn() -> void:
	# find fainted actors and clean them up
	# if there are more monsters in the team then make a forced switch
	# if there arent more monsters either win or lose
	pass


func _set_current_actor() -> void:
	current_actor = turn_queue[turn_index].actor


func _turn_index_too_big() -> bool:
	if turn_index >= turn_queue.size():
		turn_index = 0
		return true
	return false


func _resolve_action_list(choice: Choice) -> ActionList:
	if choice == null or choice.action_or_list == null:
		return null
	match choice.type:
		Choice.Type.MOVE:
			var move: Move = choice.action_or_list as Move
			return move.action_list if move != null else null
		Choice.Type.ITEM:
			var item: Item = choice.action_or_list as Item
			return item.actions if item != null else null
		Choice.Type.SWITCH, Choice.Type.FLEE:
			return choice.action_or_list if choice.action_or_list is ActionList else null
	return null


func _create_wild_battle(monster_data: MonsterData, level: int) -> void:
	player_actors.clear()
	enemy_actors.clear()

	player_team = PlayerContext3D.party_handler.party

	var monster = monster_data.set_up(level)
	enemy_team = [monster]

	player_actors = { 0: player_team[0] }
	enemy_actors = { 0: enemy_team[0] }

	actors_changed.emit(player_actors, enemy_actors)
