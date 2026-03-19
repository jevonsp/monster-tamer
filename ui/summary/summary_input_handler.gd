extends Node

@onready var summary: Control = $".."

func _unhandled_input(event: InputEvent) -> void:
	if not summary.processing:
		return

	if summary.is_learning_move:
		await _handle_learning_input(event)
	elif summary.is_move_focused:
		_handle_move_focused_input(event)
	else:
		_handle_default_input(event)


func _handle_default_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		summary.visibility_focus_handler._toggle_visible()
		Global.on_summary_closed.emit()
		if not summary.in_battle:
			Global.toggle_player.emit()
	elif event.is_action_pressed("no"):
		summary.visibility_focus_handler._toggle_visible()
		Global.on_summary_closed.emit()
		if not summary.in_battle:
			Global.request_open_party.emit()
	elif event.is_action_pressed("right"):
		summary.cycle_monster(1)
	elif event.is_action_pressed("left"):
		summary.cycle_monster(-1)
	elif event.is_action_pressed("yes"):
		summary.visibility_focus_handler._focus_default_move()
	else:
		return

	get_viewport().set_input_as_handled()


func _handle_move_focused_input(event: InputEvent) -> void:
	if event.is_action_pressed("yes"):
		if not summary.is_moving_move:
			summary.start_moving_move()
		else:
			summary.finish_moving_move()
	elif event.is_action_pressed("no"):
		summary.visibility_focus_handler._unfocus_moves()
	else:
		return

	get_viewport().set_input_as_handled()


func _handle_learning_input(event: InputEvent) -> void:
	if event.is_action_pressed("no"):
		await summary.handle_cancel_learning()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("yes"):
		await summary.ask_remove_move()
		get_viewport().set_input_as_handled()
