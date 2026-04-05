class_name MoveLearningController
extends Node


func resolve_move_learning(summary: Control, monster: Monster, move: Move) -> void:
	summary.learning_monster = monster
	summary.move_learning = move

	var learn_index := monster.get_learn_index()
	if learn_index >= 0:
		monster.learn_move(move, learn_index)
		await announce_move_learned(monster, move)
		clean_up_learning_move(summary)
		return

	var decided := false
	while not decided:
		var answer = await ask_delete_existing_move(monster, move)
		if not answer:
			decided = await handle_cancel_learning(summary)
			continue
		decided = true

	summary.is_learning_move = true
	Party.request_summary_learn_move.emit(move)
	if not summary.visible:
		summary.visibility_focus_handler.set_visible(true, monster)
	else:
		summary.show_monster(monster)
	summary.processing = true
	summary.visibility_focus_handler.focus_default_move()


func ask_remove_move(summary: Control) -> void:
	if \
	summary.last_focused_move_button == null or \
	summary.move_learning == null or \
	summary.learning_monster == null:
		return

	var move_removing = summary.last_focused_move_button.move
	if move_removing == null:
		return

	set_move_learning_processing(summary, false, "confirm_replace_move prompt")
	var answer: bool = await confirm_replace_move(move_removing, summary.move_learning)
	await Ui.text_box_complete
	if not answer:
		set_move_learning_processing(summary, true, "confirm_replace_move declined")
		summary.visibility_focus_handler.focus_default_move()
		return

	var replacing_index = summary.move_panels.find(summary.last_focused_move_button)
	if replacing_index == -1:
		set_move_learning_processing(summary, true, "confirm_replace_move missing index")
		return

	summary.learning_monster.learn_move(summary.move_learning, replacing_index)
	summary.update_handler.display_monster(summary.learning_monster)
	summary.visibility_focus_handler.unfocus_moves()
	summary.is_learning_move = false
	await announce_move_learned(summary.learning_monster, summary.move_learning)
	clean_up_learning_move(summary)


func handle_cancel_learning(summary: Control) -> bool:
	if summary.learning_monster == null or summary.move_learning == null:
		return false

	set_move_learning_processing(summary, false, "confirm_stop_learning prompt")
	var answer: bool = await confirm_stop_learning(summary.learning_monster, summary.move_learning)
	await Ui.text_box_complete
	if not answer:
		set_move_learning_processing(summary, true, "confirm_stop_learning declined")
		summary.visibility_focus_handler.focus_default_move()
		return false

	await show_did_not_learn(summary.learning_monster, summary.move_learning)
	clean_up_learning_move(summary)
	return true


func set_move_learning_processing(summary: Control, value: bool, _reason: String) -> void:
	summary.processing = value


func clean_up_learning_move(summary: Control) -> void:
	summary.is_moving_move = false
	summary.move_learning = null
	Ui.move_learning_finished.emit()
	summary.visibility_focus_handler.toggle_visible()
	Party.player_party_requested.emit()


func ask_delete_existing_move(monster: Monster, move: Move) -> bool:
	var text: Array[String] = [
		"%s is trying to learn %s, but already knows four moves. Delete one?" % [monster.name, move.name],
	]
	Ui.send_text_box.emit(null, text, false, true, false)
	return await Ui.answer_given


func confirm_replace_move(old_move: Move, new_move: Move) -> bool:
	var text: Array[String] = [
		"Are you sure you want to remove %s for %s?" % [old_move.name, new_move.name],
	]
	Ui.send_text_box.emit(null, text, false, true, false)
	return await Ui.answer_given


func confirm_stop_learning(monster: Monster, move: Move) -> bool:
	var text: Array[String] = [
		"Are you sure you want %s to stop learning %s" % [monster.name, move.name],
	]
	Ui.send_text_box.emit(null, text, false, true, false)
	return await Ui.answer_given


func show_did_not_learn(monster: Monster, move: Move) -> void:
	var ta: Array[String] = ["%s did not learn %s" % [monster.name, move.name]]
	Ui.send_text_box.emit(
		null,
		ta,
		true,
		false,
		false,
	)
	await Ui.text_box_complete


func announce_move_learned(monster: Monster, move: Move) -> void:
	await MoveLearningController.show_move_learned_message(monster, move)

static func show_move_learned_message(monster: Monster, move: Move) -> void:
	var ta: Array[String] = ["%s learned %s." % [monster.name, move.name]]
	Ui.send_text_box.emit(
		null,
		ta,
		true,
		false,
		false,
	)
	await Ui.text_box_complete
