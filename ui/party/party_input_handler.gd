extends Node

@onready var party: Control = $".."

#region Helper Nodes
@onready var visibility_focus_handler: Node = $"../Visibility&FocusHandler"
#endregion


func _unhandled_input(event: InputEvent) -> void:
	if not party.processing:
		return

	if event.is_action_pressed("menu"):
		if not party.is_forced_switch:
			visibility_focus_handler._toggle_visible()
			Global.on_party_closed.emit()
			Global.toggle_player.emit()
			get_viewport().set_input_as_handled()

	if event.is_action_pressed("no"):
		_handle_no_input()


func _handle_no_input() -> void:
	match party.interfaces.ui_context:
		Global.AccessFrom.INVENTORY:
			visibility_focus_handler._toggle_visible()
			Global.on_party_closed.emit()
			Global.switch_ui_context.emit(Global.AccessFrom.PARTY)
			Global.request_open_inventory.emit()
			return
		Global.AccessFrom.BATTLE:
			if not party.is_forced_switch:
				visibility_focus_handler._toggle_visible()
				Global.on_party_closed.emit()
			return

	if not party.options_box.visible:
		visibility_focus_handler._toggle_visible()
		Global.on_party_closed.emit()
		Global.request_open_menu.emit()
	else:
		visibility_focus_handler._toggle_options_visible()

	get_viewport().set_input_as_handled()


func _on_monster_pressed(button: Button) -> void:
	party.last_selected_monster = button
	var num := int(button.name.trim_prefix("Panel"))

	match party.interfaces.ui_context:
		Global.AccessFrom.PARTY:
			match party.state:
				party.State.DEFAULT:
					party.moving_source_index = num
					visibility_focus_handler._toggle_options_visible()
				party.State.MOVING:
					party.stop_moving(num)

		Global.AccessFrom.INVENTORY:
			Global.monster_selected.emit(button.actor)

		Global.AccessFrom.BATTLE:
			await _handle_battle_press(button, num)


func _handle_battle_press(button: Button, num: int) -> void:
	if not party.is_forced_switch:
		if num == 0:
			Global.send_text_box.emit(null, ["That monster is already fighting!"], true, false, false)
			await Global.text_box_complete
			return
		Global.request_switch_creation.emit(num)
		visibility_focus_handler._toggle_visible()
	else:
		if not button.actor.is_able_to_fight:
			Global.send_text_box.emit(null, ["That monster is not able to fight!"], true, false, false)
			await Global.text_box_complete
			return
		Global.send_selected_force_switch.emit(button.actor)
		party.is_forced_switch = false
		visibility_focus_handler._toggle_visible()


func _on_option_pressed(button: Button) -> void:
	party.last_selected_option = button

	match button.name:
		"Summary":
			party.open_summary()
		"Move":
			party.start_moving()
		"Use":
			party.use()
		"Give":
			party.give()
		"Take":
			party.take()

	get_viewport().set_input_as_handled()
