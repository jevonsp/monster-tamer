class_name BattleChassis
extends Resource

signal actors_changed(p_actors: Dictionary[int, Monster], e_actors: Dictionary[int, Monster])

@export var player_team: Array[Monster] = []
@export var enemy_team: Array[Monster] = []
@export var player_actors: Dictionary[int, Monster] = { }
@export var enemy_actors: Dictionary[int, Monster] = { }

var in_battle: bool = false
var turn_queue: Array[Choice] = []
var turn_index: int = 0
var current_actor: Monster
var trainer: Trainer3D
var _processing_turn: bool = false


func _init() -> void:
	if not Battle.wild_battle_requested.is_connected(_create_wild_battle):
		Battle.wild_battle_requested.connect(_create_wild_battle)


func resolve_turn(presenter: BattlePresenter) -> void:
	_prune_invalid_choices_from_turn_queue()
	if turn_queue.is_empty():
		return

	_processing_turn = true
	while not turn_queue.is_empty() and in_battle:
		var choice: Choice = turn_queue[0]
		current_actor = choice.actor

		var action_list := _resolve_action_list(choice)
		if action_list == null:
			turn_queue.pop_at(0)
			_prune_invalid_choices_from_turn_queue()
			continue

		var ctx := ActionContext.new(self, choice, presenter)
		await action_list.run(ctx)
		turn_queue.pop_at(0)
		_prune_invalid_choices_from_turn_queue()
		await _clean_up_turn()

	turn_queue.clear()
	turn_index = 0
	_processing_turn = false


func advance_turn() -> void:
	Battle.enqueue_enemy_move_choice()
	_sort_turn_queue()
	await resolve_turn(Battle.presenter)


func is_player_actor(monster: Monster) -> bool:
	return true if monster in player_team else false


func is_enemy_actor(monster: Monster) -> bool:
	return true if monster in enemy_team else false


func change_actor(
		team: Dictionary[int, Monster],
		out_monster: Monster,
		in_monster: Monster,
) -> bool:
	for k in team.keys():
		if team[k] == out_monster:
			team[k] = in_monster
			actors_changed.emit(player_actors, enemy_actors)
			return true
	return false


func is_processing_turn():
	return _processing_turn


func _sort_turn_queue() -> void:
	turn_queue.sort_custom(func(a: Choice, b: Choice) -> bool: return _choice_before(a, b))


func _choice_before(a: Choice, b: Choice) -> bool:
	var pa := _prio(a)
	var pb := _prio(b)
	if pa != pb:
		return pa > pb
	var aspd := a.actor.speed if a.actor else 0
	var bspd := b.actor.speed if b.actor else 0
	if aspd != bspd:
		return aspd > bspd
	var at := a.targets[0].speed if a.targets.size() > 0 and a.targets[0] else 0
	var bt := b.targets[0].speed if b.targets.size() > 0 and b.targets[0] else 0
	return at > bt


func _prio(c: Choice) -> int:
	match c.type:
		Choice.Type.SWITCH, Choice.Type.FLEE:
			return 6
		Choice.Type.MOVE:
			var m: Move = c.action_or_list as Move
			return m.priority if m else 0
		Choice.Type.ITEM:
			var i: Item = c.action_or_list as Item
			return i.priority if i else 7
	return 0


func _prune_invalid_choices_from_turn_queue() -> void:
	var kept: Array[Choice] = []
	for choice: Choice in turn_queue:
		if _choice_is_valid(choice):
			kept.append(choice)
	turn_queue.assign(kept)


func _choice_is_valid(choice: Choice) -> bool:
	if choice == null or choice.actor == null or choice.actor.is_fainted:
		return false
	if not choice.targets.is_empty():
		var t: Monster = choice.targets[0]
		if t != null and t.is_fainted:
			return false
	return true


func _clean_up_turn() -> void:
	for idx: int in enemy_actors.keys():
		var em: Monster = enemy_actors[idx]
		if em != null and em.is_fainted:
			enemy_actors.erase(idx)

	var next_enemy: Monster = _get_next_enemy_actor()
	if next_enemy != null:
		enemy_actors[0] = next_enemy
		actors_changed.emit(player_actors, enemy_actors)
	elif not enemy_team.is_empty():
		await _end_battle_won()
		return

	for idx: int in player_actors.keys():
		var pm: Monster = player_actors[idx]
		if pm != null and pm.is_fainted:
			player_actors.erase(idx)

	var next_player: Monster = _get_next_player_actor()
	if next_player != null:
		player_actors[0] = next_player
		actors_changed.emit(player_actors, enemy_actors)
	elif not player_team.is_empty():
		await _end_battle_lost()


func _get_next_enemy_actor() -> Monster:
	for monster: Monster in enemy_team:
		if monster != null and not monster.is_fainted:
			return monster
	return null


func _get_next_player_actor() -> Monster:
	for monster: Monster in player_team:
		if monster != null and not monster.is_fainted:
			return monster
	return null


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
	in_battle = true

	player_actors.clear()
	enemy_actors.clear()

	player_team = PlayerContext3D.party_handler.party

	var monster = monster_data.set_up(level)
	enemy_team = [monster]

	player_actors = { 0: _get_next_player_actor() }
	enemy_actors = { 0: _get_next_enemy_actor() }

	actors_changed.emit(player_actors, enemy_actors)


func _end_battle_won() -> void:
	var ctx := ActionContext.new(self, null, Battle.presenter)
	var ta: Array[String] = ["You won!"]
	@warning_ignore("redundant_await")
	await ctx.presenter.show_text(ctx, ta, false)
	in_battle = false
	Battle.battle_ended.emit(trainer)
	player_actors.clear()
	enemy_actors.clear()


func _end_battle_lost() -> void:
	var ctx := ActionContext.new(self, null, Battle.presenter)
	var ta: Array[String] = ["You have no Pokémon able to fight!"]
	@warning_ignore("redundant_await")
	await ctx.presenter.show_text(ctx, ta, false)
	in_battle = false
	Battle.battle_ended.emit(trainer)
	player_actors.clear()
	enemy_actors.clear()
