extends Node


func ask_delete_existing_move(monster: Monster, move: Move) -> bool:
	var text: Array[String] = [
		"%s is trying to learn %s, but already knows four moves. Delete one?"
		% [monster.name, move.name]
	]
	Global.send_text_box.emit(monster, text, false, true, false)
	return await Global.answer_given


func confirm_replace_move(old_move: Move, new_move: Move) -> bool:
	var text: Array[String] = [
		"Are you sure you want to remove %s for %s?" % [old_move.name, new_move.name]
	]
	Global.send_text_box.emit(null, text, false, true, false)
	return await Global.answer_given


func confirm_stop_learning(monster: Monster, move: Move) -> bool:
	var text: Array[String] = [
		"Are you sure you want %s to stop learning %s" % [monster.name, move.name]
	]
	Global.send_text_box.emit(null, text, false, true, false)
	return await Global.answer_given


func show_did_not_learn(monster: Monster, move: Move) -> void:
	Global.send_text_box.emit(
		null,
		["%s did not learn %s" % [monster.name, move.name]],
		false,
		false,
		false
	)
	await Global.text_box_complete


func announce_move_learned(monster: Monster, move: Move) -> void:
	Global.send_text_box.emit(
		monster,
		["%s learned %s." % [monster.name, move.name]],
		false,
		false,
		false
	)
	await Global.text_box_complete
