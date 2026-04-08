extends Node

var run_count: int = 0

@onready var battle: Control = $".."


func execute_turn_queue(
		handler: Node,
		turn_queue: Array[Dictionary],
		post_action_resolver: Node,
) -> bool:
	# Clear lingering battle text at the start of each turn.
	var text_box := battle.get_tree().get_first_node_in_group("game_text_box")
	if text_box and text_box.has_method("clear_text"):
		text_box.clear_text()

	_sort_turn_queue(turn_queue)

	var battle_context := BattleContext.new(handler, battle)
	for entry in turn_queue:
		if not _is_relevant_entry(entry):
			continue

		var actor: Monster = entry.actor
		var target: Monster = entry.target

		if _should_skip_entry(actor, target):
			continue

		actor.reset_status_turn_state()
		await actor.tick_statuses_start(battle_context)
		if _should_skip_entry(actor, target):
			continue
		if not actor.can_attempt_action(battle_context):
			var text_array := actor.get_action_block_text()
			if not text_array.is_empty():
				await battle_context.show_text(text_array)
			await actor.tick_statuses_end(battle_context)
			if battle.enemy_actor and battle.enemy_actor.is_fainted:
				if await post_action_resolver.handle_post_action(battle.enemy_actor, handler):
					return true
			elif battle.player_actor and battle.player_actor.is_fainted:
				if await post_action_resolver.handle_post_action(battle.player_actor, handler):
					return true
			continue
		if actor.has_action_override(battle_context, entry.action):
			await actor.execute_action_override(target, battle_context, entry.action)
			if _should_skip_entry(actor, target):
				continue
			if await post_action_resolver.handle_post_action(actor, handler):
				return true
			await actor.tick_statuses_end(battle_context)
			if battle.enemy_actor and battle.enemy_actor.is_fainted:
				if await post_action_resolver.handle_post_action(battle.enemy_actor, handler):
					return true
			elif battle.player_actor and battle.player_actor.is_fainted:
				if await post_action_resolver.handle_post_action(battle.player_actor, handler):
					return true
			continue

		if entry.action is Move:
			target = _resolve_move_target(actor, target, entry.action)
		if entry.action is Run:
			run_count += 1

		await entry.action.execute(actor, target, battle_context)

		if await post_action_resolver.handle_post_action(target, handler):
			return true

		if _should_skip_entry(actor, target):
			continue

		if _should_skip_entry(actor, target):
			continue

		await actor.tick_statuses_end(battle_context)

		if battle.enemy_actor and battle.enemy_actor.is_fainted:
			if await post_action_resolver.handle_post_action(battle.enemy_actor, handler):
				return true
		elif battle.player_actor and battle.player_actor.is_fainted:
			if await post_action_resolver.handle_post_action(battle.player_actor, handler):
				return true

	return false


func _sort_turn_queue(turn_queue: Array[Dictionary]) -> void:
	turn_queue.sort_custom(
		func(a, b):
			if a.action.priority != b.action.priority:
				return a.action.priority > b.action.priority
			return a.actor.get_effective_speed() > b.actor.get_effective_speed()
	)


func _is_relevant_entry(entry: Dictionary) -> bool:
	if not (entry.action is Move):
		return true

	var actor: Monster = entry.actor
	return actor == battle.player_actor or actor == battle.enemy_actor


func _should_skip_entry(actor: Monster, target: Monster) -> bool:
	return not actor.is_able_to_fight or target == null or not target.is_able_to_fight


func _resolve_move_target(actor: Monster, target: Monster, move: Move) -> Monster:
	if move.is_self_targeting:
		return actor
	if actor == battle.player_actor:
		return battle.enemy_actor
	if actor == battle.enemy_actor:
		return battle.player_actor
	return target
