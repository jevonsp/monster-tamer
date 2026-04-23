class_name SayCommand
extends Command

@export_multiline() var text: Array[String] = []
@export var is_autocomplete: bool = false


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

	Ui.send_text_box.emit(null, text, is_autocomplete, false, false)
	await Ui.text_box_complete

	return true


func after_trigger() -> bool:
	if should_exit:
		return false
	if not should_trigger:
		return true

	# Clean up command here

	return true
