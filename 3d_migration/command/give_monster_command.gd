class_name GiveMonsterCommand
extends Command

@export var monster_data: MonsterData = null
@export_multiline() var text: Array[String] = ["You found a level {level} {name}"]
@export var level: int = 1
@export var needs_formatting: bool = true
@export var is_question: bool = false

func format_text() -> Array[String]:
	var formatted: Array[String] = []
	for string in text:
		formatted.append(
			string.format(
				{
					"level": level,
					"name": monster_data.species,
				},
			),
		)
	return formatted


func _trigger_impl(_owner: Node) -> Flow:
	text = format_text() if needs_formatting else text

	if is_question:
		Ui.send_text_box.emit(null, text, false, true, false)
		var answer: bool = await Ui.answer_given
		await Ui.text_box_complete
		if not answer:
			return Flow.STOP
		var monster: Monster = monster_data.set_up(level)
		PlayerContext3D.party_handler.add(monster)
		return Flow.NEXT
	else:
		Ui.send_text_box.emit(null, text, false, false, false)
		await Ui.text_box_complete
		var monster: Monster = monster_data.set_up(level)
		PlayerContext3D.party_handler.add(monster)

	return Flow.NEXT
