class_name GiveItemCommand
extends Command

@export var item: Item = null
@export_multiline() var text: Array[String] = ["You found {amount} {item_name}"]
@export var quantity: int = 1
@export var needs_formatting: bool = true
@export var is_question: bool = false


func before_trigger() -> bool:
	if should_exit:
		return false
	if not should_trigger:
		return true

	# Do pre trigger stuff here

	return true


func trigger() -> bool:
	if should_exit:
		return false
	if not should_trigger:
		return true

	text = format_text() if needs_formatting else text

	if is_question:
		Ui.send_text_box.emit(null, text, false, true, false)
		var answer = await Ui.answer_given
		if answer:
			PlayerContext3D.inventory_handler.add(item, quantity)
		return answer
	else:
		Ui.send_text_box.emit(null, text, false, false, false)

	PlayerContext3D.inventory_handler.add(item, quantity)

	return true


func after_trigger() -> bool:
	if should_exit:
		return false
	if not should_trigger:
		return true

	# Clean up command here

	return true


func format_text() -> Array[String]:
	var formatted: Array[String]

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
