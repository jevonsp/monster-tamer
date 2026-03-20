extends Node
@onready var battle: Control = $".."
@onready var forced_switch_handler: Node = $"../ForcedSwitchHandler"


func handle_post_action(target: Monster, handler: Node) -> bool:
	if handler.is_escaped:
		_escape()
		return true
	
	await _resolve_faint_aftermath(target)

	if _check_enemy_actor_captured():
		print_debug("BATTLE: enemy actor captured")
		_capture()
		return true
	
	if not _check_enemy_actor_able_to_fight():
		print_debug("BATTLE: enemy actor not able to fight")
		if _check_enemy_out_of_monsters():
			print_debug("BATTLE: enemy out of monsters -> win.")
			await _win()
			return true
		print_debug("BATTLE: enemy needs new monster -> force switch.")
		await forced_switch_handler.force_enemy_send_new_monster(handler)
		return false

	if not _check_player_actor_able_to_fight():
		print_debug("BATTLE: player actor not able to fight")
		if _check_player_out_of_monsters():
			print_debug("BATTLE: player out of monsters -> lose.")
			await _lose()
			return true
		print_debug("BATTLE: player needs new monster -> force switch.")
		await forced_switch_handler.force_player_send_new_monster(handler)
		return false

	return false


func resolve_level_up(monster: Monster, amount: int) -> void:
	print_debug(
		"EXP: resolving level-up in battle for %s amount=%s level=%s"
		% [monster.name, amount, monster.level]
	)
	var text_array: Array[String] = ["%s leveled up to %s." % [monster.name, monster.level]]
	Global.send_text_box.emit(null, text_array, false, false, false)
	await Global.text_box_complete
	print_debug("EXP: %s level-up text complete" % [monster.name])

	if monster.check_should_gain_moves():
		print_debug("EXP: %s should gain move at level=%s" % [monster.name, monster.level])
		var move_to_learn: Move = monster.get_move_to_learn()
		if move_to_learn != null:
			Global.request_summary_move_learning.emit(monster, move_to_learn)
			print_debug("EXP: %s waiting for move_learning_finished" % [monster.name])
			await Global.move_learning_finished
			print_debug("EXP: %s move_learning_finished" % [monster.name])

	Global.battle_level_up_resolution_complete.emit()


func _resolve_faint_aftermath(target: Monster) -> void:
	if target == null or not target.is_fainted:
		return

	print_debug("BATTLE: post_action target fainted target=%s is_player=%s" % [target.name, target.is_player_monster])
	var text_array: Array[String] = ["%s fainted!" % [target.name]]
	Global.send_text_box.emit(null, text_array, true, false, false)
	await Global.text_box_complete
	print_debug("BATTLE: %s faint text complete" % [target.name])

	if target.is_player_monster:
		return

	var exp_amount = Monster.EXPERIENCE_PER_LEVEL * target.level
	print_debug("BATTLE: %s send_monster_death_experience amount=%s" % [target.name, exp_amount])
	Global.send_monster_death_experience.emit(exp_amount)
	print_debug("BATTLE: fainted enemy %s. Waiting for EXP distribution to finish." % [target.name])
	await Global.player_done_giving_exp
	print_debug("BATTLE: EXP distribution complete.")


func _check_player_actor_able_to_fight() -> bool:
	return battle.player_actor.is_able_to_fight


func _check_enemy_actor_able_to_fight() -> bool:
	return battle.enemy_actor.is_able_to_fight


func _check_enemy_actor_captured() -> bool:
	return battle.enemy_actor != null and battle.enemy_actor.is_captured


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
	var text: Array[String] = battle.enemy_trainer.losing_dialogue if battle.enemy_trainer else default
	Global.send_text_box.emit(null, text, false, false, false)
	await Global.text_box_complete
	battle.end_battle()


func _lose() -> void:
	var text: Array[String] = ["You lost!"]
	Global.send_text_box.emit(null, text, false, false, false)
	await Global.text_box_complete
	battle.end_battle()
	Global.send_respawn_player.emit()
	
	
func _escape() -> void:
	battle.end_battle()


func _capture() -> void:
	battle.end_battle()
