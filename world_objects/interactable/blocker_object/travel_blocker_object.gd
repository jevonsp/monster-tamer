class_name TravelBlockerObject
extends BlockerObject

enum TravelRequirement { MOVE, ITEM }

@export var travel_requirment: TravelRequirement


func interact(body: Player) -> void:
	var ta: Array[String]
	if body.available_travel_methods[Player.TravelState.SURFING] != true:
		ta = [cant_interact_text]
		Ui.send_text_box.emit(null, ta, false, false, true)
		await Ui.text_box_complete
		return

	ta = [question_interact_text]
	Ui.send_text_box.emit(self, ta, false, true, false)
	var answer = await Ui.answer_given
	if answer:
		print("yes")
