extends Node
@onready var battle: Control = $".."
var turn_queue: Array[Dictionary] = []
var executing_turn: bool = false


func _ready() -> void:
	Global.add_item_to_turn_queue.connect(_execute_player_turn)
	Global.add_switch_to_turn_queue.connect(_execute_player_turn)


func _execute_player_turn(action) -> void:
	if executing_turn or not battle.processing:
		return
	print_debug("BATTLE: _execute_player_turn action=%s" % [action])
	if _add_action_to_queue(action, battle.player_actor):
		battle.processing = false
		battle.visibility_focus_handler._manage_focus()
		print_debug("BATTLE: player action queued; requesting enemy action")
		_get_enemy_action()
		print_debug("BATTLE: executing turn queue size=%s" % [turn_queue.size()])
		await _execute_turn_queue()
		battle.processing = true


func _get_enemy_action() -> void:
	var available_moves: Array[Move] = []
	for move in battle.enemy_actor.moves:
		if move != null:
			available_moves.append(move)
	if not available_moves.is_empty():
		var picked = available_moves.pick_random()
		print_debug("BATTLE: enemy picked move=%s" % [picked])
		_add_action_to_queue(picked, battle.enemy_actor)


func _add_action_to_queue(action, actor: Monster) -> bool:
	if action == null:
		return false
	if action is Move or action is Item:
		var target: Monster = _get_target(actor, action)
		print_debug("BATTLE: queue action=%s actor=%s target=%s" % [action, actor.name, target.name if target else "null"])
		turn_queue.append({
			"action": action,
			"actor": actor,
			"target": target
		})
	elif action is Switch:
		print_debug("BATTLE: queue switch actor=%s target=%s" % [action.actor.name, action.target.name])
		turn_queue.append({
			"action": action,
			"actor": action.actor,
			"target": action.target
		})
	return true


func _get_target(actor: Monster, action) -> Monster:
	if action is Move:
		if action.is_self_targeting:
			return actor

	if action is Item:
		if action.use_effect is HealingEffect:
			return actor
		if action.catch_effect:
			return battle.enemy_actor

	return battle.enemy_actor if actor == battle.player_actor else battle.player_actor


func _execute_turn_queue() -> void:
	executing_turn = true
	_sort_turn_queue()
	print_debug("BATTLE: turn queue sorted size=%s" % [turn_queue.size()])

	var battle_context := BattleContext.new(self, battle)
	
	for entry in turn_queue:

		if not _is_relevant_entry(entry):
			print_debug("BATTLE: skipping irrelevant entry action=%s" % [entry.action])
			continue

		var actor: Monster = entry.actor
		var target: Monster = entry.target
		print_debug("BATTLE: entry start action=%s actor=%s target=%s" % [entry.action, actor.name, target.name if target else "null"])
		
		if _should_exit_action(actor, target):
			print_debug("BATTLE: entry exit before statuses actor=%s target=%s" % [actor.name, target.name if target else "null"])
			continue
		
		await _tick_statuses_start(actor, battle_context)
		
		if _should_exit_action(actor, target):
			print_debug("BATTLE: entry exit after statuses_start actor=%s target=%s" % [actor.name, target.name if target else "null"])
			continue
		
		if entry.action is Move:
			target = _resolve_move_target(actor, target, entry.action)
			print_debug("BATTLE: resolved move target=%s" % [target.name if target else "null"])
			
		await entry.action.execute(actor, target, battle_context)
		print_debug("BATTLE: action execute complete action=%s actor=%s target=%s" % [entry.action, actor.name, target.name if target else "null"])
		
		if _should_exit_action(actor, target):
			print_debug("BATTLE: entry exit after action actor=%s target=%s" % [actor.name, target.name if target else "null"])
			continue
		
		if await _handle_post_action(target):
			print_debug("BATTLE: post_action ended battle for target=%s" % [target.name if target else "null"])
			return
		
		if _should_exit_action(actor, target):
			print_debug("BATTLE: entry exit after post_action actor=%s target=%s" % [actor.name, target.name if target else "null"])
			continue
		
		await _tick_statuses_end(actor, battle_context)
		print_debug("BATTLE: entry end statuses_end actor=%s" % [actor.name])
		
		if battle.enemy_actor and battle.enemy_actor.is_fainted:
			if await _handle_post_action(battle.enemy_actor):
				return
		elif battle.player_actor and battle.player_actor.is_fainted:
			if await _handle_post_action(battle.player_actor):
				return
		
	_reset_turn_state()


func _should_exit_action(actor: Monster, target: Monster) -> bool:
	var should_exit = not actor.is_able_to_act or not target.is_able_to_act
	if should_exit:
		print_debug("BATTLE: should_exit_action actor=%s target=%s actor_can_act=%s target_can_act=%s" \
				% [actor.name, target.name if target else "null", actor.is_able_to_act, target.is_able_to_act])
	return should_exit


func _tick_statuses_start(actor: Monster, context: BattleContext) -> void:
	await actor.tick_statuses_start(context)


func _tick_statuses_end(actor: Monster, context: BattleContext) -> void:
	await actor.tick_statuses_end(context)


func _is_relevant_entry(entry: Dictionary) -> bool:
	if not (entry.action is Move):
		return true

	var actor: Monster = entry.actor
	if actor == battle.player_actor:
		return true
	if actor == battle.enemy_actor:
		return true
		
	return false


func _resolve_move_target(actor: Monster, target: Monster, move: Move) -> Monster:
	if move.is_self_targeting:
		return actor

	var is_player_side: bool = actor == battle.player_actor
	var is_enemy_side: bool = actor == battle.enemy_actor

	if is_player_side:
		return battle.enemy_actor
	if is_enemy_side:
		return battle.player_actor

	return target


func _handle_post_action(target: Monster) -> bool:
	if target and target.is_fainted and not target.is_player_monster:
		print_debug("BATTLE: post_action target fainted target=%s is_player=%s" % [target.name, target.is_player_monster])
		print_debug("BATTLE: fainted enemy %s. Waiting for EXP distribution to finish." % [target.name])
		await Global.player_done_giving_exp
		print_debug("BATTLE: EXP distribution complete.")
	
	if not _check_enemy_actor_able_to_fight():
		print_debug("BATTLE: enemy actor not able to fight")
		if _check_enemy_out_of_monsters():
			print_debug("BATTLE: enemy out of monsters -> win.")
			_win()
			return true
		else:
			print_debug("BATTLE: enemy needs new monster -> force switch.")
			await _force_enemy_send_new_monster() 
			return false
	
	if not _check_player_actor_able_to_fight():
		print_debug("BATTLE: player actor not able to fight")
		if _check_player_out_of_monsters():
			print_debug("BATTLE: player out of monsters -> lose.")
			_lose()
			return true
		else:
			print_debug("BATTLE: player needs new monster -> force switch.")
			await _force_player_send_new_monster()
			return false

	return false


func _check_player_actor_able_to_fight() -> bool:
	return battle.player_actor.is_able_to_fight


func _check_enemy_actor_able_to_fight() -> bool:
	return battle.enemy_actor.is_able_to_fight


func _force_player_send_new_monster():
	print_debug("BATTLE: force_player_send_new_monster begin")
	Global.request_forced_switch.emit()
	print_debug("BATTLE: waiting for send_selected_force_switch")
	var target = await Global.send_selected_force_switch
	print_debug("BATTLE: received forced switch target=%s" % [target.name if target else "null"])
	
	var switch = Switch.new()
	switch.actor = battle.player_actor
	switch.target = target
	
	var battle_context = BattleContext.new(self, battle)
	print_debug("BATTLE: executing forced player switch actor=%s target=%s" % [switch.actor.name, switch.target.name])
	await switch.execute(switch.actor, switch.target, battle_context)
	print_debug("BATTLE: forced player switch complete")


func _force_enemy_send_new_monster():
	var available_monsters: Array[Monster]
	for monster: Monster in battle.enemy_party:
		if monster.is_able_to_fight:
			available_monsters.append(monster)
	
	var next_monster = available_monsters.pick_random()
	print_debug("BATTLE: enemy force switch available=%s picked=%s" % [available_monsters.size(), next_monster.name if next_monster else "null"])
	var switch = Switch.new()
	
	switch.actor = battle.enemy_actor
	switch.target = next_monster
	switch.out_unformatted = "Enemy %s withdrew %%s." % [battle.enemy_trainer.npc_name]
	switch.in_unformatted = "Enemy %s sent out %%s." % [battle.enemy_trainer.npc_name]
	
	var battle_context = BattleContext.new(self, battle)
	print_debug("BATTLE: executing forced enemy switch actor=%s target=%s" % [switch.actor.name, switch.target.name])
	await switch.execute(switch.actor, switch.target, battle_context)
	print_debug("BATTLE: forced enemy switch complete")


func _reset_turn_state() -> void:
	print_debug("BATTLE: reset turn state")
	turn_queue.clear()
	battle.processing = true
	executing_turn = false
	battle.visibility_focus_handler._manage_focus()


func _sort_turn_queue() -> void:
	turn_queue.sort_custom(func(a, b):
		if a.action.priority != b.action.priority:
			return a.action.priority > b.action.priority
		return a.actor.speed > b.actor.speed
	)


func _check_enemy_out_of_monsters() -> bool:
	for monster in battle.enemy_party:
		if monster.is_able_to_fight:
			return false
	return true


func _check_player_out_of_monsters() -> bool:
	for monster in battle.player_party:
		if monster.is_able_to_fight:
			return false
	return true


func _win() -> void:
	if battle.enemy_trainer:
		battle.enemy_trainer.is_defeated = true
	var default: Array[String] = ["You won!"]
	var text: Array[String] = \
			battle.enemy_trainer.losing_dialogue if battle.enemy_trainer else default
	Global.send_text_box.emit(null, text, false, false, false)
	await Global.text_box_complete
	battle.end_battle()


func _lose() -> void:
	var text: Array[String] = ["You lost!"]
	Global.send_text_box.emit(null, text, false, false, false)
	await Global.text_box_complete
	battle.end_battle()
	Global.send_respawn_player.emit()
