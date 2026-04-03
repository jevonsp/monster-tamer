class_name TeachEffect
extends ItemEffect

@export var move: Move


func use(target: Monster) -> void:
	if move == null:
		return

	var ta: Array[String]

	if move in target.moves:
		ta = ["%s already knows %s."]
		Ui.send_text_box.emit(null, ta, false, false, false)
		await Ui.text_box_complete
		return

	if not target.monster_data.can_learn_move(move):
		ta = ["%s can't learn %s."]
		Ui.send_text_box.emit(null, ta, false, false, false)
		await Ui.text_box_complete
		return

	ta = ["Teach %s to %s?"]
	Ui.send_text_box.emit(null, ta, false, true, false)
	var answer: bool = await Ui.answer_given
	await Ui.text_box_complete

	if not answer:
		return

	Party.request_summary_move_learning.emit(target, move)
	await Ui.move_learning_finished
