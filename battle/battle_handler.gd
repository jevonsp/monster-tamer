extends Node
@onready var battle: Control = $".."
var turn_queue: Array[Dictionary] = []

func _execute_player_turn(move: Move) -> void:
	if _add_move_to_queue(move, battle.player_actor):
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
		_add_move_to_queue(available_moves.pick_random(), battle.enemy_actor)


func _add_move_to_queue(move: Move, actor: Monster) -> bool:
	if move == null:
		return false
	
	var target: Monster = _get_target(actor, move)
	turn_queue.append({
		"action": move,
		"actor": actor,
		"target": target
	})
	return true


func _get_target(actor: Monster, move: Move) -> Monster:
	if move.is_self_targeting:
		return actor
	return battle.enemy_actor if actor == battle.player_actor else battle.player_actor


func _execute_turn_queue() -> void:
	_sort_turn_queue()
	
	for entry in turn_queue:
		var actor: Monster = entry.actor
		var target: Monster = entry.target
		var exp_completed = [false]
		var on_exp_complete = func(): exp_completed[0] = true
		Global.experience_animation_complete.connect(on_exp_complete, CONNECT_ONE_SHOT)
		
		await entry.action.execute(actor, target)
		if target and target.is_fainted and target == battle.enemy_actor:
			if not exp_completed[0]:
				await Global.experience_animation_complete
		
		if _check_enemy_out_of_monsters():
			_win()
			return
		if _check_player_out_of_monsters():
			_lose()
			return
			
	turn_queue.clear()
	battle.processing = true
	battle.input_handler._manage_focus()


func _sort_turn_queue() -> void:
	turn_queue.sort_custom(func(a, b): 
		if a.action.priority != b.action.priority:
			return a.action.priority > b.action.priority
		return a.actor.speed > b.actor.speed
	)


func _check_enemy_out_of_monsters() -> bool:
	for monster in battle.enemy_party:
		if not monster.is_fainted:
			return false
	return true


func _check_player_out_of_monsters() -> bool:
	for monster in battle.player_party:
		if not monster.is_fainted:
			return false
	return true


func _win() -> void:
	var text: Array[String] = ["You won!"]
	Global.send_battle_text_box.emit(text, false)
	await Global.battle_text_box_complete
	battle.end_battle()


func _lose() -> void:
	var text: Array[String] = ["You lost!"]
	Global.send_battle_text_box.emit(text, false)
	await Global.battle_text_box_complete
	battle.end_battle()
	Global.send_respawn_player.emit()
