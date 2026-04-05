extends Node

@onready var summary: Control = $".."
@onready var party: Control = $"../../Party"


func highlight_move_swap() -> void:
	_set_move_panel_focus_style(summary.BUTTON_PANEL_FOCUS_MOVING_STYLEBOX)


func clear_move_swap_highlight() -> void:
	_set_move_panel_focus_style(summary.BUTTON_PANEL_FOCUS_DEFAULT_STYLEBOX)


func toggle_visible(monster: Monster = null) -> void:
	set_visible(not summary.visible, monster)


func set_visible(value: bool, monster: Monster = null) -> void:
	if value and summary.interfaces.ui_context == Global.AccessFrom.PARTY and party.visible:
		party.visibility_focus_handler.set_visible(false)
		Ui.switch_ui_context.emit(Global.AccessFrom.PARTY)

	summary.visible = value
	summary.processing = value

	if monster != null:
		summary.show_monster(monster)

	if not summary.visible:
		_reset_summary_state()


func set_move_focus(button: Button) -> void:
	summary.last_focused_move_button = button


func focus_default_move() -> void:
	summary.is_move_focused = true
	if summary.last_focused_move_button:
		summary.last_focused_move_button.grab_focus()
		return
	summary.move_panels[0].grab_focus()


func unfocus_moves() -> void:
	if summary.last_focused_move_button:
		summary.last_focused_move_button.release_focus()
		summary.last_focused_move_button = null
	summary.moving_index_one = -1
	summary.is_move_focused = false
	_set_move_panel_focus_style(summary.BUTTON_PANEL_FOCUS_DEFAULT_STYLEBOX)


func _reset_summary_state() -> void:
	summary.update_handler.clear_monster()
	summary.is_move_focused = false
	summary.is_learning_move = false
	summary.is_moving_move = false
	summary.move_learning = null
	summary.learning_monster = null
	summary.last_focused_move_button = null
	summary.moving_index_one = -1
	clear_move_swap_highlight()


func _set_move_panel_focus_style(style: StyleBoxTexture) -> void:
	for button in summary.move_panels:
		button.add_theme_stylebox_override("focus", style)
