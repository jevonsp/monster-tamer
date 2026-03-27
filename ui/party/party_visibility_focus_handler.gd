extends Node

@onready var party: Control = $".."


func toggle_visible() -> void:
	set_visible(not party.visible)


func set_visible(value: bool) -> void:
	party.visible = value
	party.processing = value

	if party.visible:
		focus_default_monster()
		for panel in party.panels:
			party.panels[panel].player_exp_bar.active = true
	else:
		if party.interfaces.ui_context != Global.AccessFrom.BATTLE:
			Global.switch_ui_context.emit(Global.AccessFrom.NONE)
		for panel in party.panels:
			party.panels[panel].player_exp_bar.active = false

	if party.visible and party.options_box.visible:
		focus_default_option()


func toggle_options_visible() -> void:
	party.options_box.visible = not party.options_box.visible

	if party.options_box.visible:
		focus_default_option()
	else:
		focus_default_monster()


func set_monster_focus(button: Button) -> void:
	party.last_selected_monster = button


func set_option_focus(button: Button) -> void:
	party.last_selected_option = button


func focus_default_monster() -> void:
	if party.last_selected_monster and party.last_selected_monster.actor != null:
		party.last_selected_monster.grab_focus()
		return

	var keys: Array = party.panels.keys()
	if keys.is_empty():
		return

	party.panels[keys[0]].grab_focus()


func focus_default_option() -> void:
	if party.last_selected_option and party.last_selected_option.is_inside_tree():
		party.last_selected_option.grab_focus()
		return

	var keys: Array = party.option_buttons.keys()
	if keys.is_empty():
		return

	party.last_selected_option = party.option_buttons[keys[0]]
	party.last_selected_option.grab_focus()
