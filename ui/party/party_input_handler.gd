extends Node

@onready var party: Control = $".."
@onready var visibility_focus_handler: Node = $"../Visibility&FocusHandler"
@onready var inventory: Control = $"../../Inventory"


func _unhandled_input(event: InputEvent) -> void:
	if not party.processing:
		return

	if event.is_action_pressed("menu"):
		if not party.is_forced_switch:
			visibility_focus_handler.toggle_visible()
			Ui.on_party_closed.emit()
			if not PlayerContext3D.player.in_battle:
				Ui.on_menu_closed.emit()
			get_viewport().set_input_as_handled()

	if event.is_action_pressed("no"):
		_handle_no_input()


func on_monster_pressed(button: Button) -> void:
	party.last_selected_monster = button
	var num := int(button.name.trim_prefix("Panel"))

	if _is_inventory_target_pick():
		Ui.monster_selected.emit(button.actor)
		return

	if _is_battle_context():
		await _handle_battle_press(button, num)
		return

	match party.state:
		party.State.DEFAULT:
			party.moving_source_index = num
			visibility_focus_handler.toggle_options_visible()
		party.State.MOVING:
			party.stop_moving(num)


func on_option_pressed(button: Button) -> void:
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


func _handle_no_input() -> void:
	if _is_inventory_target_pick():
		visibility_focus_handler.toggle_visible()
		Ui.on_party_closed.emit()
		Ui.switch_ui_context.emit(Global.AccessFrom.PARTY)
		Ui.request_open_inventory.emit()
		return

	if _is_battle_context():
		if not party.is_forced_switch:
			visibility_focus_handler.toggle_visible()
			Ui.on_party_closed.emit()
		return

	if not party.options_box.visible:
		visibility_focus_handler.toggle_visible()
		Ui.on_party_closed.emit()
		Ui.request_open_menu.emit()
	else:
		visibility_focus_handler.toggle_options_visible()

	get_viewport().set_input_as_handled()


func _handle_battle_press(button: Button, num: int) -> void:
	if not party.is_forced_switch:
		if num == 0:
			Ui.send_text_box.emit(null, ["That monster is already fighting!"], true, false, false)
			await Ui.text_box_complete
			return
		Ui.request_switch_creation.emit(num)
		visibility_focus_handler.toggle_visible()
	else:
		if not button.actor.is_able_to_fight:
			Ui.send_text_box.emit(null, ["That monster is not able to fight!"], true, false, false)
			await Ui.text_box_complete
			return
		Battle.submit_forced_switch(button.actor)
		party.is_forced_switch = false
		visibility_focus_handler.toggle_visible()


func _is_battle_context() -> bool:
	var player = PlayerContext3D.player
	return player != null and player.in_battle


func _is_inventory_target_pick() -> bool:
	return inventory != null and inventory.has_method("is_waiting_for_party_target") and inventory.is_waiting_for_party_target()
