class_name GiveItemCommand
extends Command

@export var item: Item = null
@export_multiline() var text: Array[String] = ["You found {amount} {item_name}"]
@export var quantity: int = 1
@export var needs_formatting: bool = true
@export var is_question: bool = false


func format_text() -> Array[String]:
	var formatted: Array[String] = []
	for string in text:
		formatted.append(
			string.format(
				{
					"amount": quantity,
					"item_name": item.name,
				},
			),
		)
	return formatted


func _trigger_impl(owner: Node) -> Flow:
	text = format_text() if needs_formatting else text

	if is_question:
		Ui.send_text_box.emit(null, text, false, true, false)
		var answer: bool = await Ui.answer_given
		if not answer:
			return Flow.STOP
		PlayerContext3D.inventory_handler.add(item, quantity)
		return Flow.NEXT
	else:
		Ui.send_text_box.emit(null, text, false, false, false)

	PlayerContext3D.inventory_handler.add(item, quantity)
	return Flow.NEXT
