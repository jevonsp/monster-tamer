extends RefCounted


func add_action_to_queue(
	action,
	actor: Monster,
	battle: Control,
	turn_queue: Array[Dictionary]
) -> bool:
	if action == null:
		return false
	if action is Move or action is Item:
		var target: Monster = _get_target(actor, action, battle)
		turn_queue.append({
			"action": action,
			"actor": actor,
			"target": target
		})
	elif action is Switch:
		turn_queue.append({
			"action": action,
			"actor": action.actor,
			"target": action.target
		})
	elif action is Run:
		var target = battle.enemy_actor if actor == battle.player_actor else battle.player_actor
		turn_queue.append({
			"action": action,
			"actor": actor,
			"target": target
		})
	return true


func queue_enemy_action(battle: Control, turn_queue: Array[Dictionary]) -> void:
	var available_moves: Array[Move] = []
	for move in battle.enemy_actor.moves:
		if move != null:
			available_moves.append(move)
	if available_moves.is_empty():
		return

	var picked = available_moves.pick_random()
	add_action_to_queue(picked, battle.enemy_actor, battle, turn_queue)


func _get_target(actor: Monster, action, battle: Control) -> Monster:
	if action is Move and action.is_self_targeting:
		return actor

	if action is Item:
		if action.use_effect is HealingEffect:
			return actor
		if action.catch_effect:
			return battle.enemy_actor

	return battle.enemy_actor if actor == battle.player_actor else battle.player_actor
