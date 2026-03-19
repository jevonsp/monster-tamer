extends Node
@onready var battle: Control = $".."
var run_count: int = 0

func execute_turn_queue(
	handler: Node,
	turn_queue: Array[Dictionary],
	post_action_resolver: Node
) -> bool:
	_sort_turn_queue(turn_queue)
	print_debug("BATTLE: turn queue sorted size=%s" % [turn_queue.size()])

	var battle_context := BattleContext.new(handler, battle)
	for entry in turn_queue:
		if not _is_relevant_entry(entry):
			print_debug("BATTLE: skipping irrelevant entry action=%s" % [entry.action])
			continue

		var actor: Monster = entry.actor
		var target: Monster = entry.target
		print_debug(
			"BATTLE: entry start action=%s actor=%s target=%s"
			% [entry.action, actor.name, target.name if target else "null"]
		)

		if _should_exit_action(actor, target):
			print_debug(
				"BATTLE: entry exit before statuses actor=%s target=%s"
				% [actor.name, target.name if target else "null"]
			)
			continue

		await actor.tick_statuses_start(battle_context)
		if _should_exit_action(actor, target):
			print_debug(
				"BATTLE: entry exit after statuses_start actor=%s target=%s"
				% [actor.name, target.name if target else "null"]
			)
			continue

		if entry.action is Move:
			target = _resolve_move_target(actor, target, entry.action)
			print_debug("BATTLE: resolved move target=%s" % [target.name if target else "null"])
		if entry.action is Run:
			run_count += 1
			
		await entry.action.execute(actor, target, battle_context)
		print_debug(
			"BATTLE: action execute complete action=%s actor=%s target=%s"
			% [entry.action, actor.name, target.name if target else "null"]
		)

		if _should_exit_action(actor, target):
			print_debug(
				"BATTLE: entry exit after action actor=%s target=%s"
				% [actor.name, target.name if target else "null"]
			)
			continue

		if await post_action_resolver.handle_post_action(target, handler):
			print_debug("BATTLE: post_action ended battle for target=%s" % [target.name if target else "null"])
			return true

		if _should_exit_action(actor, target):
			print_debug(
				"BATTLE: entry exit after post_action actor=%s target=%s"
				% [actor.name, target.name if target else "null"]
			)
			continue

		await actor.tick_statuses_end(battle_context)
		print_debug("BATTLE: entry end statuses_end actor=%s" % [actor.name])

		if battle.enemy_actor and battle.enemy_actor.is_fainted:
			if await post_action_resolver.handle_post_action(battle.enemy_actor, handler):
				return true
		elif battle.player_actor and battle.player_actor.is_fainted:
			if await post_action_resolver.handle_post_action(battle.player_actor, handler):
				return true

	return false


func _sort_turn_queue(turn_queue: Array[Dictionary]) -> void:
	turn_queue.sort_custom(func(a, b):
		if a.action.priority != b.action.priority:
			return a.action.priority > b.action.priority
		return a.actor.speed > b.actor.speed
	)


func _is_relevant_entry(entry: Dictionary) -> bool:
	if not (entry.action is Move):
		return true

	var actor: Monster = entry.actor
	return actor == battle.player_actor or actor == battle.enemy_actor


func _should_exit_action(actor: Monster, target: Monster) -> bool:
	var should_exit = not actor.is_able_to_act or not target.is_able_to_act
	if should_exit:
		print_debug(
			"BATTLE: should_exit_action actor=%s target=%s actor_can_act=%s target_can_act=%s"
			% [actor.name, target.name if target else "null", actor.is_able_to_act, target.is_able_to_act]
		)
	return should_exit


func _resolve_move_target(actor: Monster, target: Monster, move: Move) -> Monster:
	if move.is_self_targeting:
		return actor
	if actor == battle.player_actor:
		return battle.enemy_actor
	if actor == battle.enemy_actor:
		return battle.player_actor
	return target
