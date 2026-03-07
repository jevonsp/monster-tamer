extends Node
@onready var battle: Control = $".."
var turn_queue: Array[Dictionary] = []
var executing_turn: bool = false


func _ready() -> void:
	Global.add_item_to_turn_queue.connect(_execute_player_turn)
	Global.add_switch_to_turn_queue.connect(_execute_player_turn)


func _execute_player_turn(action) -> void:
	if _add_action_to_queue(action, battle.player_actor):
		battle.processing = false
		battle.input_handler._manage_focus()
		_get_enemy_action()
		await _execute_turn_queue()
		battle.processing = true


func _get_enemy_action() -> void:
	var available_moves: Array[Move] = []
	for move in battle.enemy_actor.moves:
		if move != null:
			available_moves.append(move)
	if not available_moves.is_empty():
		_add_action_to_queue(available_moves.pick_random(), battle.enemy_actor)


func _add_action_to_queue(action, actor: Monster) -> bool:
	if action == null:
		return false
	if action is Move or action is Item:
		var target: Monster = _get_target(actor, action)
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
	for entry in turn_queue:
		if not _is_relevant_entry(entry):
			continue

		var actor: Monster = entry.actor
		var target: Monster = entry.target

		if entry.action is Move:
			target = _resolve_move_target(actor, target, entry.action)

		await entry.action.execute(actor, target)

		if await _handle_post_action(target):
			return

	_reset_turn_state()


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
	if target and target.is_fainted and target == battle.enemy_actor:
		await Global.player_done_giving_exp

	if _check_enemy_out_of_monsters():
		_win()
		return true

	if _check_player_out_of_monsters():
		_lose()
		return true

	return false


func _reset_turn_state() -> void:
	turn_queue.clear()
	battle.processing = true
	executing_turn = false
	battle.input_handler._manage_focus()


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
	var text: Array[String] = ["You won!"]
	Global.send_battle_text_box.emit(text, false)
	await Global.text_box_complete
	battle.end_battle()


func _lose() -> void:
	var text: Array[String] = ["You lost!"]
	Global.send_battle_text_box.emit(text, false)
	await Global.text_box_complete
	battle.end_battle()
	Global.send_respawn_player.emit()
