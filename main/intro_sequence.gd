extends Control

signal model_choice(choice: PlayerInfo3D.Model)

@onready var model_buttons: HBoxContainer = $ModelButtons
@onready var a_model_button: Button = $ModelButtons/AModel
@onready var b_model_button: Button = $ModelButtons/BModel


func _ready() -> void:
	_connect_signals()


func play_intro_sequence() -> void:
	var interfaces := get_parent()
	if interfaces.has_method("begin_field_suppress"):
		interfaces.begin_field_suppress()

	var ta: Array[String] = ["Hello! Whats your name?"]
	Ui.send_text_box.emit(null, ta, false, false, false)
	await Ui.text_box_complete

	Ui.text_cancel_info.emit(false, "You gotta tell me your name!")
	var outcome: Dictionary = await Ui.await_text_entry_outcome(false, 0)
	if outcome.get("failed", false) or outcome.get("cancelled", false):
		pass

	var entered_name: String = outcome.get("text", "") as String
	PlayerContext3D.player_info_handler.player_name = entered_name

	ta = ["So you're called %s" % entered_name]
	Ui.send_text_box.emit(null, ta, false, false, false)
	await Ui.text_box_complete

	ta = ["And are you a boy, girl, or something else?"]
	var choices: Array[String] = ["Enby", "Girl", "Boy"]
	var entered_gender: String = await Ui.await_choice(ta, choices)
	var response: String = ""
	match entered_gender:
		"Enby":
			PlayerContext3D.player_info_handler.player_gender = PlayerInfo3D.Gender.NB
			response = "a cool person!"
		"Girl":
			PlayerContext3D.player_info_handler.player_gender = PlayerInfo3D.Gender.FEMALE
			response = "a girl!"
		"Boy":
			PlayerContext3D.player_info_handler.player_gender = PlayerInfo3D.Gender.MALE
			response = "a boy!"

	ta = ["I'll address you as %s" % response]
	Ui.send_text_box.emit(null, ta, false, false, false)
	await Ui.text_box_complete

	ta = ["What do you look like?"]
	Ui.send_text_box.emit(null, ta, true, false, false)
	await Ui.text_box_complete

	await get_tree().process_frame
	model_buttons.visible = true
	a_model_button.call_deferred("grab_focus")

	var choice = await model_choice
	PlayerContext3D.player_info_handler.player_model = choice

	model_buttons.visible = false
	if interfaces.has_method("end_field_suppress"):
		interfaces.end_field_suppress()
	visible = false


func _connect_signals() -> void:
	a_model_button.pressed.connect(func(): model_choice.emit(PlayerInfo3D.Model.A))
	b_model_button.pressed.connect(func(): model_choice.emit(PlayerInfo3D.Model.B))
