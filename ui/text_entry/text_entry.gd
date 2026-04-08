extends Control

const _SHIFT_BUTTON_NAME := "TextEntryButton10"
const _SHIFT_LABEL := "shf"
const _CAPS_LOCK_LABEL := "cap"

var can_cancel: bool = true
var cancel_message: String = "Enter a name!"
var processing: bool = false
## When true, Enter confirms even if the buffer is empty (gameplay sets this before opening).
var allow_empty_submit: bool = false
## Maximum characters; 0 means unlimited.
var max_input_length: int = 13
var string: String = "":
	set(value):
		var prev_len: int = string.length()
		string = value
		_display_string()
		if string.is_empty():
			_toggle_capitals(true)
		elif string.length() == 1:
			if prev_len == 2 and capitals.visible:
				pass
			else:
				_toggle_capitals(false)
		_refresh_shift_button_labels()
var last_focused_button: Button = null
var last_focused_group: GridContainer = null
var last_focused_index: int = -1

@onready var capitals: GridContainer = $Capitals
@onready var lowercase: GridContainer = $Lowercase
@onready var special: GridContainer = $Special
@onready var numbers: GridContainer = $Numbers
@onready var label: Label = $Panel/Label
@onready var enter_capitals: TextEntryButton = $Capitals/TextEntryButton29
@onready var enter_lowercase: TextEntryButton = $Lowercase/TextEntryButton29
@onready var cancel_capitals: TextEntryButton = $Capitals/TextEntryButton20
@onready var cancel_lowercase: TextEntryButton = $Lowercase/TextEntryButton20


func _ready() -> void:
	add_to_group("text_entry_root")
	processing = visible
	_connect_signals()
	_toggle_capitals(true)
	_refresh_shift_button_labels()
	_setup_wrapped_focus_neighbors()
	get_viewport().gui_focus_changed.connect(_on_viewport_focus_changed)
	call_deferred("_ensure_text_entry_focus")


func _input(event: InputEvent) -> void:
	if not processing:
		return
	if event.is_action_pressed("no"):
		_delete()
		get_viewport().set_input_as_handled()
		call_deferred("_ensure_text_entry_focus")
	elif event.is_action_pressed("menu"):
		_enter()
		get_viewport().set_input_as_handled()
		call_deferred("_ensure_text_entry_focus")


func reset_for_prompt() -> void:
	if visible:
		_close_and_reset()
	else:
		string = ""
	allow_empty_submit = false
	max_input_length = 0
	capitals.visible = false
	lowercase.visible = true
	special.visible = false
	numbers.visible = true


func _connect_signals() -> void:
	Ui.request_text_entry.connect(_toggle_visible)
	Ui.text_cancel_info.connect(_set_text_cancel_info)
	var buttons = get_tree().get_nodes_in_group("text_entry_buttons")
	for button: Button in buttons:
		button.button_clicked.connect(_on_button_clicked)
		button.focus_entered_info.connect(_on_focus_entered)


func _on_viewport_focus_changed(node: Control) -> void:
	if not processing or not visible:
		return
	if node != null and is_instance_valid(node) and is_ancestor_of(node):
		return
	call_deferred("_ensure_text_entry_focus")


func _ensure_text_entry_focus() -> void:
	if not is_inside_tree() or not processing or not visible:
		return
	var focus_owner: Control = get_viewport().gui_get_focus_owner() as Control
	if focus_owner != null and is_instance_valid(focus_owner) and is_ancestor_of(focus_owner):
		return
	if last_focused_button != null and is_instance_valid(last_focused_button) and last_focused_button.is_visible_in_tree():
		last_focused_button.grab_focus()
		return
	_grab_default_keyboard_focus()


func _refocus_parallel_letter_key(from_button: TextEntryButton) -> void:
	var parent_grid: GridContainer = from_button.get_parent() as GridContainer
	if parent_grid != capitals and parent_grid != lowercase:
		return
	var idx: int = from_button.get_index()
	var target: GridContainer = _visible_letter_grid()
	if target == null or idx < 0 or idx >= target.get_child_count():
		return
	call_deferred("_grab_focus_control", target.get_child(idx))


func _grab_focus_control(ctrl: Control) -> void:
	if not is_instance_valid(ctrl) or not ctrl.is_visible_in_tree():
		return
	ctrl.grab_focus()


func _grab_default_keyboard_focus() -> void:
	var counterpart: Control = _counterpart_control_for_last_focus()
	if counterpart != null:
		counterpart.grab_focus()
		return
	var letter := _visible_letter_grid()
	if letter != null and letter.get_child_count() > 0:
		letter.get_child(0).grab_focus()
		return
	var top := _visible_top_strip()
	if top != null and top.get_child_count() > 0:
		top.get_child(0).grab_focus()


func _counterpart_control_for_last_focus() -> Control:
	var idx: int = -1
	var group: GridContainer = null
	if last_focused_button != null and is_instance_valid(last_focused_button):
		idx = last_focused_button.get_index()
		group = last_focused_button.get_parent() as GridContainer
	elif last_focused_index >= 0 and last_focused_group != null and is_instance_valid(last_focused_group):
		idx = last_focused_index
		group = last_focused_group
	if idx < 0 or group == null:
		return null
	if group == capitals or group == lowercase:
		var target: GridContainer = _visible_letter_grid()
		if target == null:
			return null
		idx = clampi(idx, 0, target.get_child_count() - 1)
		return target.get_child(idx) as Control
	if group == numbers or group == special:
		var target: GridContainer = _visible_top_strip()
		if target == null:
			return null
		idx = clampi(idx, 0, target.get_child_count() - 1)
		return target.get_child(idx) as Control
	return null


func _toggle_visible() -> void:
	capitals.visible = false
	lowercase.visible = true
	special.visible = false
	numbers.visible = true

	visible = not visible
	processing = visible
	if visible:
		string = ""
		_refresh_shift_button_labels()
		_setup_wrapped_focus_neighbors()
		call_deferred("_ensure_text_entry_focus")


func _on_button_clicked(from_button: TextEntryButton, chr: String, is_special: bool, act: TextEntryButton.Action) -> void:
	if not is_special:
		_add_character(chr)
		if is_instance_valid(from_button) and not from_button.is_visible_in_tree():
			_refocus_parallel_letter_key(from_button)
	else:
		match act:
			TextEntryButton.Action.DELETE:
				_remove_character()
			TextEntryButton.Action.SHIFT:
				_shift_characters()
			TextEntryButton.Action.CANCEL:
				_cancel()
			TextEntryButton.Action.ENTER:
				_enter()
			_:
				pass


func _on_focus_entered(button: Button, grid_container: GridContainer) -> void:
	last_focused_button = button
	last_focused_group = grid_container
	last_focused_index = button.get_index()


func _add_character(chr: String) -> void:
	if max_input_length > 0 and string.length() >= max_input_length:
		return
	string += chr


func _remove_character() -> bool:
	if string.length() > 0:
		string = string.erase(string.length() - 1, 1)
		return true
	return false


func _display_string() -> void:
	label.text = string


func _toggle_capitals(value: bool) -> void:
	capitals.visible = value
	lowercase.visible = not value
	_refresh_shift_button_labels()
	_setup_wrapped_focus_neighbors()


func _shift_characters() -> void:
	var containers = [capitals, lowercase, special, numbers]
	for container in containers:
		container.visible = not container.visible
	_refresh_shift_button_labels()
	_setup_wrapped_focus_neighbors()
	_refocus_shift_button()


func _refresh_shift_button_labels() -> void:
	if not is_node_ready():
		return
	_set_shift_label_on_grid(capitals, true)
	_set_shift_label_on_grid(lowercase, false)


func _set_shift_label_on_grid(grid: GridContainer, is_capitals_grid: bool) -> void:
	if not grid.has_node(_SHIFT_BUTTON_NAME):
		return
	var btn: TextEntryButton = grid.get_node(_SHIFT_BUTTON_NAME)
	if is_capitals_grid:
		btn.character = _CAPS_LOCK_LABEL if not string.is_empty() else _SHIFT_LABEL
	else:
		btn.character = _SHIFT_LABEL


func _refocus_shift_button() -> void:
	if capitals.visible and capitals.has_node(_SHIFT_BUTTON_NAME):
		capitals.get_node(_SHIFT_BUTTON_NAME).grab_focus()
	elif lowercase.visible and lowercase.has_node(_SHIFT_BUTTON_NAME):
		lowercase.get_node(_SHIFT_BUTTON_NAME).grab_focus()


func _setup_wrapped_focus_neighbors() -> void:
	for grid in [capitals, lowercase, special, numbers]:
		_apply_wrapped_neighbors_to_grid(grid)
	_link_letter_grid_with_top_strip()


func _visible_letter_grid() -> GridContainer:
	if lowercase.visible:
		return lowercase
	if capitals.visible:
		return capitals
	return null


func _visible_top_strip() -> GridContainer:
	if numbers.visible:
		return numbers
	if special.visible:
		return special
	return null


func _link_letter_grid_with_top_strip() -> void:
	var letter: GridContainer = _visible_letter_grid()
	var top: GridContainer = _visible_top_strip()
	if letter == null or top == null:
		return
	var cols: int = mini(mini(letter.columns, top.columns), 10)
	# Letter grid is 3×10: row0 = 0–9, row2 = 20–29.
	for col in range(cols):
		var letter_top: Control = letter.get_child(col) as Control
		var letter_bot: Control = letter.get_child(20 + col) as Control
		var strip_btn: Control = top.get_child(col) as Control
		if letter_top == null or letter_bot == null or strip_btn == null:
			continue
		# Top strip sits above the letter block: strip <-> letter row 0, and vertical wrap with letter row 2.
		letter_top.set_focus_neighbor(SIDE_TOP, letter_top.get_path_to(strip_btn))
		strip_btn.set_focus_neighbor(SIDE_BOTTOM, strip_btn.get_path_to(letter_top))
		letter_bot.set_focus_neighbor(SIDE_BOTTOM, letter_bot.get_path_to(strip_btn))
		strip_btn.set_focus_neighbor(SIDE_TOP, strip_btn.get_path_to(letter_bot))


func _apply_wrapped_neighbors_to_grid(grid: GridContainer) -> void:
	var cols: int = maxi(1, grid.columns)
	var buttons: Array[Control] = []
	for c in grid.get_children():
		if c is Control and (c as Control).focus_mode != Control.FOCUS_NONE:
			buttons.append(c)
	var n: int = buttons.size()
	if n == 0:
		return
	var rows: int = ceili(float(n) / float(cols))
	for i in range(n):
		var row: int = int(float(i) / float(cols))
		var col: int = i % cols
		var btn: Control = buttons[i]
		var left_i: int = row * cols + (col - 1 + cols) % cols
		var right_i: int = row * cols + (col + 1) % cols
		if left_i < n:
			btn.set_focus_neighbor(SIDE_LEFT, btn.get_path_to(buttons[left_i]))
		if right_i < n:
			btn.set_focus_neighbor(SIDE_RIGHT, btn.get_path_to(buttons[right_i]))
		if rows <= 1:
			continue
		var up_row: int = row - 1 if row > 0 else rows - 1
		var down_row: int = row + 1 if row < rows - 1 else 0
		var up_i: int = up_row * cols + col
		var down_i: int = down_row * cols + col
		if up_i < n:
			btn.set_focus_neighbor(SIDE_TOP, btn.get_path_to(buttons[up_i]))
		if down_i < n:
			btn.set_focus_neighbor(SIDE_BOTTOM, btn.get_path_to(buttons[down_i]))


func _cancel() -> void:
	if can_cancel:
		Ui.text_cancel_pressed.emit()
		_close_and_reset()
	else:
		var ta: Array[String] = [cancel_message]
		Ui.send_text_box.emit(null, ta, true, false, false)
		await Ui.text_box_complete


func _enter() -> void:
	var enter_focused = \
	true if enter_capitals.has_focus() or enter_lowercase.has_focus() else false
	if not enter_focused:
		if capitals.visible:
			enter_capitals.grab_focus()
			return
		else:
			enter_lowercase.grab_focus()
			return

	if string.length() > 0 or allow_empty_submit:
		var submitted: String = string
		Ui.text_enter_pressed.emit(submitted)
		_close_and_reset()


func _close_and_reset() -> void:
	allow_empty_submit = false
	max_input_length = 0
	string = ""
	visible = false
	processing = false
	capitals.visible = false
	lowercase.visible = true
	special.visible = false
	numbers.visible = true
	can_cancel = true
	cancel_message = "Enter a name!"


func _delete() -> void:
	if _remove_character():
		return

	var cancel_focused = \
	true if cancel_capitals.has_focus() or cancel_lowercase.has_focus() else false
	if not cancel_focused:
		if capitals.visible:
			cancel_capitals.grab_focus()
			return
		else:
			cancel_lowercase.grab_focus()
			return


func _set_text_cancel_info(value: bool, message: String) -> void:
	can_cancel = value
	cancel_message = message
