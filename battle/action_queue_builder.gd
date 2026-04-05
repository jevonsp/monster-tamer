extends RefCounted


func add_action_to_queue(
		action,
		actor: Monster,
		battle: Control,
		turn_queue: Array[Dictionary],
) -> bool:
	if action == null:
		return false
	if action is Move or action is Item:
		var target: Monster = _get_target(actor, action, battle)
		turn_queue.append(
			{
				"action": action,
				"actor": actor,
				"target": target,
			},
		)
	elif action is Switch:
		turn_queue.append(
			{
				"action": action,
				"actor": action.actor,
				"target": action.target,
			},
		)
	elif action is Run:
		var target = battle.enemy_actor if actor == battle.player_actor else battle.player_actor
		turn_queue.append(
			{
				"action": action,
				"actor": actor,
				"target": target,
			},
		)
	return true


func queue_enemy_action(battle: Control, turn_queue: Array[Dictionary]) -> void:
	var enemy: Monster = battle.enemy_actor
	if battle.is_wild_battle:
		var available_moves: Array[Move] = []
		for move in enemy.moves:
			if move != null and enemy.has_pp(move):
				available_moves.append(move)
		if available_moves.is_empty():
			return

		var enemy_move = available_moves.pick_random()
		enemy.decrement_pp(enemy_move)

		add_action_to_queue(enemy_move, enemy, battle, turn_queue)
	else:
		var enemy_move = get_enemy_move_from_battle(battle)
		enemy.decrement_pp(enemy_move)

		add_action_to_queue(enemy_move, enemy, battle, turn_queue)


func get_enemy_move_from_battle(battle: Control) -> Move:
	var enemy: Monster = battle.enemy_actor
	var available_moves: Dictionary[Move, int] = { }
	for i in enemy.moves.size():
		if enemy.moves[i] != null:
			available_moves[enemy.moves[i]] = 0

	for move: Move in available_moves:
		_check_type_efficacy(battle, move, available_moves)
		_check_status_component(battle, move, available_moves)
		_check_stat_boost_component(battle, move, available_moves)

	return _get_best_move(available_moves)


func _get_target(actor: Monster, action, battle: Control) -> Monster:
	if action is Move and action.is_self_targeting:
		return actor

	if action is Item:
		if action.use_effect is HealingEffect:
			return actor
		if action.catch_effect:
			return battle.enemy_actor

	return battle.enemy_actor if actor == battle.player_actor else battle.player_actor


func _get_component(move: Move, component_type) -> MoveEffect:
	return move.effects.filter(func(e): return is_instance_of(e, component_type)).front()


func _has_component_of_type(move: Move, component_type) -> bool:
	return move.effects.any(func(e): return is_instance_of(e, component_type))


func _check_type_efficacy(battle: Control, move: Move, dict: Dictionary[Move, int]) -> void:
	var player: Monster = battle.player_actor
	var type_efficacy = TypeChart.get_attacking_type_efficacy(move.type, player)
	if type_efficacy > 1:
		dict[move] += 1
	elif type_efficacy < 1:
		dict[move] -= 1


func _check_status_component(battle: Control, move: Move, dict: Dictionary[Move, int]) -> void:
	if _has_component_of_type(move, ApplyStatusEffect):
		var component: ApplyStatusEffect = _get_component(move, ApplyStatusEffect)
		var status_data = component.status_data
		var player: Monster = battle.player_actor
		if player.has_status(status_data.status_name):
			dict[move] -= 1


func _check_stat_boost_component(battle: Control, move: Move, dict: Dictionary[Move, int]) -> void:
	if _has_component_of_type(move, StatBoostEffect):
		var component: StatBoostEffect = _get_component(move, StatBoostEffect)
		var stat: Monster.Stat = component.stat
		var stage_amount: int = component.stage_amount
		var enemy: Monster = battle.enemy_actor
		var current_stages: int = enemy.stat_stages_and_multis.stat_stages[stat]
		if current_stages + stage_amount > 6:
			dict[move] -= 1
		elif current_stages + stage_amount < -6:
			dict[move] -= 1


func _get_best_move(moves: Dictionary[Move, int]) -> Move:
	var best_move: Move = null
	var best_score = -INF
	for move in moves:
		if moves[move] > best_score:
			best_score = moves[move]
			best_move = move
	return best_move
