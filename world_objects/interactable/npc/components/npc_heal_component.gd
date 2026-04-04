class_name NPCHealComponent
extends NPCComponent


func trigger(obj: Node) -> NPCComponent.Result:
	if obj.is_in_group("player"):
		obj.party_handler.fully_heal_and_revive_party()

		var ta: Array[String] = ["Your party has been healed back to full."]
		Ui.send_text_box.emit(null, ta, true, false, false)
		await Ui.text_box_complete

	return NPCComponent.Result.CONTINUE
