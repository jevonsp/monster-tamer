class_name TravelBlockerObject
extends BlockerObject

@export var requirement: Player.TravelState = Player.TravelState.DEFAULT


func interact(body: Player) -> void:
	var ta: Array[String]
	if requirement not in FieldCapability.get_available_travel_methods():
		ta = [cant_interact_text]
		Ui.send_text_box.emit(null, ta, false, false, true)
		await Ui.text_box_complete
		return

	ta = [question_interact_text]
	Ui.send_text_box.emit(self, ta, false, true, false)
	var answer = await Ui.answer_given
	await Ui.text_box_complete
	if answer:
		match requirement:
			Player.TravelState.DEFAULT:
				await body.walk_to_tile(body.facing_direction)
			Player.TravelState.SURFING:
				await body.travel.start_surfing()
