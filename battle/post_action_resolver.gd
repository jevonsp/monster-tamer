extends Node

@onready var battle: Control = $".."
@onready var forced_switch_handler: Node = $"../ForcedSwitchHandler"


func handle_post_action(target: Monster, handler: Node) -> bool:
	if handler.is_escaped:
		_escape()
		return true

	await _resolve_faint_aftermath(target)

	if _check_enemy_actor_captured():
		_capture()
		return true

	if not _check_enemy_actor_able_to_fight():
		if _check_enemy_out_of_monsters():
			await _win()
			return true
		await forced_switch_handler.force_enemy_send_new_monster(handler)
		return false

	if not _check_player_actor_able_to_fight():
		if _check_player_out_of_monsters():
			await _lose()
			return true
		await forced_switch_handler.force_player_send_new_monster(handler)
		return false

	return false


func resolve_level_up(monster: Monster, _amount: int) -> void:
	var text_array: Array[String] = ["%s leveled up to %s." % [monster.name, monster.level]]
	Ui.send_text_box.emit(null, text_array, false, false, false)
	await Ui.text_box_complete

	if monster.check_should_gain_moves():
		var move_to_learn: Move = monster.get_move_to_learn()
		if move_to_learn != null:
			if monster.learn_level_up_move(move_to_learn) == Monster.LevelUpMoveResult.NEEDS_SWAP:
				Party.request_summary_move_learning.emit(monster, move_to_learn)
				await Ui.move_learning_finished
			else:
				await MoveLearningController.show_move_learned_message(monster, move_to_learn)

	Battle.battle_level_up_resolution_complete.emit()


func _resolve_faint_aftermath(target: Monster) -> void:
	if target == null or not target.is_fainted:
		return

	var text_array: Array[String] = ["%s fainted!" % [target.name]]
	Ui.send_text_box.emit(null, text_array, true, false, false)
	await Ui.text_box_complete

	if target.is_player_monster:
		return

	var exp_amount = Monster.EXPERIENCE_PER_LEVEL * target.level
	Battle.send_monster_death_experience.emit(exp_amount)
	await Battle.player_done_giving_exp


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
		battle.enemy_trainer.defeat()

	var default: Array[String] = ["You won!"]
	var text: Array[String] = battle.enemy_trainer.losing_dialogue if battle.enemy_trainer else default
	Ui.send_text_box.emit(null, text, false, false, false)
	await Ui.text_box_complete
	battle.end_battle()


func _lose() -> void:
	var text: Array[String] = ["You lost!"]
	Ui.send_text_box.emit(null, text, false, false, false)
	await Ui.text_box_complete
	battle.end_battle()
	Global.send_respawn_player.emit()


func _escape() -> void:
	battle.end_battle()


func _capture() -> void:
	battle.end_battle()
