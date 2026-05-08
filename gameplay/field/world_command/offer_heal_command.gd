class_name OfferHealCommand
extends Command

@export var is_question: bool = false
@export var is_respawn_point: bool = true
@export_multiline() var question_text: String = "Would you like to heal your monsters?"


func _trigger_impl(_owner) -> Flow:
	if is_question:
		var ta: Array[String] = [question_text]
		Ui.send_text_box.emit(null, ta, false, true, false)
		var answer = await Ui.answer_given
		if not answer:
			return Flow.STOP

	var player = PlayerContext3D.player

	if is_respawn_point:
		player.set_respawn_point()

	player.party_handler.fully_heal_and_revive_party()

	return Flow.NEXT
