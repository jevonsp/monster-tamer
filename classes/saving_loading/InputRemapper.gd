class_name InputRemapper
extends Object


static func apply(scheme: Options.ControlScheme) -> void:
	match scheme:
		Options.ControlScheme.XBOX_SONY:
			_apply_sony_xbox()
		Options.ControlScheme.NINTENDO:
			_apply_nintendo()


static func _apply_sony_xbox() -> void:
	var old_yes = InputEventJoypadButton.new()
	var new_yes = InputEventJoypadButton.new()

	old_yes.button_index = JOY_BUTTON_A
	new_yes.button_index = JOY_BUTTON_B

	InputMap.action_erase_event("yes", old_yes)
	InputMap.action_add_event("yes", new_yes)

	var old_no = InputEventJoypadButton.new()
	var new_no = InputEventJoypadButton.new()

	old_no.button_index = JOY_BUTTON_B
	new_no.button_index = JOY_BUTTON_A

	InputMap.action_erase_event("no", old_no)
	InputMap.action_add_event("no", new_no)


static func _apply_nintendo() -> void:
	var old_yes = InputEventJoypadButton.new()
	var new_yes = InputEventJoypadButton.new()

	old_yes.button_index = JOY_BUTTON_B
	new_yes.button_index = JOY_BUTTON_A

	InputMap.action_erase_event("yes", old_yes)
	InputMap.action_add_event("yes", new_yes)

	var old_no = InputEventJoypadButton.new()
	var new_no = InputEventJoypadButton.new()

	old_no.button_index = JOY_BUTTON_A
	new_no.button_index = JOY_BUTTON_B

	InputMap.action_erase_event("no", old_no)
	InputMap.action_add_event("no", new_no)
