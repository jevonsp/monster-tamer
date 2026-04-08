extends Control


func _ready() -> void:
	pass


func play_intro_sequence() -> void:
	var ta: Array[String] = ["Hello! Whats your name?"]
	Ui.send_text_box.emit(null, ta, false, false, false)
	await Ui.text_box_complete

	Ui.text_cancel_info.emit(false, "You gotta tell me your name!")
	var outcome: Dictionary = await Ui.await_text_entry_outcome(false, 0)
	if outcome.get("failed", false) or outcome.get("cancelled", false):
		pass

	var entered_name: String = outcome.get("text", "") as String
	Player.player_info.player_name = entered_name

	ta = ["So you're called %s" % entered_name]
	Ui.send_text_box.emit(null, ta, true, false, false)
	await Ui.text_box_complete

	ta = ["And are you a boy, girl, or something else?"]
	var choices: Array[String] = ["Enby", "Girl", "Boy"]
	Ui.send_choices.emit(ta, choices)
	var entered_gender = await Ui.choice_given
	var response: String = ""
	match entered_gender:
		"Enby":
			Player.player_info.player_gender = Info.Gender.NB
			response = "a cool person!"
		"Girl":
			Player.player_info.player_gender = Info.Gender.FEMALE
			response = "a girl!"
		"Boy":
			Player.player_info.player_gender = Info.Gender.MALE
			response = "a boy!"

	ta = ["I'll address you as %s" % response]
	Ui.send_text_box.emit(null, ta, true, false, false)
	await Ui.text_box_complete
