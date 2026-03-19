extends Control
const INVENTORY_PANEL = preload("uid://cq60mqy70b8je")
enum Mode { BROWSE, PICK_USE_TARGET, PICK_GIVE_TARGET }
var processing: bool = false
var mode: Mode = Mode.BROWSE
var is_trainer_battle: bool = false
var last_selected_option: Button = null
var last_selected_item_button: Button = null
@onready var interfaces: CanvasLayer = $".."
@onready var v_box_container: VBoxContainer = $ScrollContainer/MarginContainer/VBoxContainer
@onready var options_box: VBoxContainer = $Options
@onready var option_buttons: Dictionary = {
	use = $Options/Use,
	give = $Options/Give,
}

func _ready() -> void:
	_connect_signals()
	_bind_buttons()
	if visible:
		_toggle_visible()


func _unhandled_input(event: InputEvent) -> void:
	if not processing:
		return
	if event.is_action_pressed("menu"):
		if interfaces.ui_context == Global.AccessFrom.BATTLE:
			_toggle_visible()
			Global.on_inventory_closed.emit()
			get_viewport().set_input_as_handled()
			return
		_toggle_visible()
		Global.on_inventory_closed.emit()
		Global.toggle_player.emit()
		get_viewport().set_input_as_handled()
		
	if event.is_action_pressed("no"):
		if interfaces.ui_context == Global.AccessFrom.BATTLE:
			_toggle_visible()
			Global.on_inventory_closed.emit()
			get_viewport().set_input_as_handled()
			return
		if interfaces.ui_context == Global.AccessFrom.PARTY:
			_toggle_visible()
			Global.switch_ui_context.emit(Global.AccessFrom.PARTY)
			Global.request_open_party.emit()
			get_viewport().set_input_as_handled()
			return
		if not options_box.visible:
			_toggle_visible()
			Global.on_inventory_closed.emit()
			Global.toggle_player.emit()
			if interfaces.ui_context == Global.AccessFrom.MENU:
				Global.request_open_menu.emit()
			interfaces.ui_context = Global.AccessFrom.NONE
		else:
			_toggle_options_visible()
		get_viewport().set_input_as_handled()


func _bind_buttons() -> void:
	for button in option_buttons:
		option_buttons[button].pressed.connect(_on_option_pressed.bind(option_buttons[button]))


func _connect_signals() -> void:
	Global.send_player_inventory.connect(_on_inventory_change)
	Global.request_open_inventory.connect(_toggle_visible)
	Global.set_inventory_use.connect(_set_mode_use_target)
	Global.set_inventory_give.connect(_set_mode_give_target)
	Global.trainer_battle_requested.connect(func(_trainer): is_trainer_battle = true)
	Global.battle_ended.connect(func(): is_trainer_battle = false)


func _on_inventory_change(inventory: Dictionary[Item, int]) -> void:
	clear_inventory_display()
	for entry in inventory.keys():
		_create_item(inventory[entry], entry)


func clear_inventory_display() -> void:
	for child in v_box_container.get_children():
		child.queue_free()


func _create_item(amount: int, item: Item) -> void:
	var inventory_panel: Button = INVENTORY_PANEL.instantiate()
	v_box_container.add_child(inventory_panel)
	inventory_panel.display(amount, item)
	inventory_panel.pressed.connect(_on_inventory_panel_pressed.bind(inventory_panel))


func _set_item_focus(inventory_panel: Button) -> void:
	last_selected_item_button = inventory_panel


func _can_use_outside_battle(item: Item) -> bool:
	return item.use_effect != null


func _can_give_to_monster(item: Item) -> bool:
	if item.catch_effect != null:
		return false
	if item.use_effect != null:
		return false
	return item.held_effect != null


func _set_mode_use_target(value: bool) -> void:
	mode = Mode.PICK_USE_TARGET if value else Mode.BROWSE


func _set_mode_give_target(value: bool) -> void:
	mode = Mode.PICK_GIVE_TARGET if value else Mode.BROWSE


func _on_inventory_panel_pressed(inventory_panel: Button) -> void:
	_set_item_focus(inventory_panel)
	var item: Item = inventory_panel.item_repr
	match interfaces.ui_context:
		Global.AccessFrom.INVENTORY:
			_toggle_options_visible()
		Global.AccessFrom.PARTY:
			match mode:
				Mode.PICK_GIVE_TARGET:
					if not _can_give_to_monster(item):
						await show_cant_hold_text()
						return
				Mode.PICK_USE_TARGET:
					if not _can_use_outside_battle(item):
						await show_cant_use_text()
						return
				_:
					if not _can_use_outside_battle(item):
						await show_cant_use_text()
						return
			_toggle_visible()
			mode = Mode.BROWSE
			Global.item_selected.emit(item)
			Global.switch_ui_context.emit(Global.AccessFrom.PARTY)
			Global.request_open_party.emit()
		Global.AccessFrom.BATTLE:
			if item.use_effect == null and item.catch_effect == null:
				await show_cant_use_in_battle_text()
				last_selected_item_button.grab_focus()
				return
			if is_trainer_battle and item.catch_effect:
				await show_cant_use_in_trainer_battle_text()
				last_selected_item_button.grab_focus()
				return
			Global.add_item_to_turn_queue.emit(item)
			Global.item_used.emit(item)
			_toggle_visible()
			mode = Mode.BROWSE


func _on_option_pressed(button: Button) -> void:
	if last_selected_item_button == null:
		return
	var item: Item = last_selected_item_button.item_repr
	last_selected_option = button
	match button.name:
		"Use":
			use(item)
		"Give":
			give(item)


func _toggle_visible() -> void:
	visible = not visible
	processing = not processing
	_focus_default()
	if not visible:
		last_selected_item_button = null
		last_selected_option = option_buttons.use
		mode = Mode.BROWSE
		options_box.visible = false
		if interfaces.ui_context != Global.AccessFrom.BATTLE:
			Global.switch_ui_context.emit(Global.AccessFrom.NONE)


func _toggle_options_visible() -> void:
	options_box.visible = not options_box.visible
	if options_box.visible:
		_focus_option_default()
	else:
		_focus_default()


func _focus_default() -> void:
	if last_selected_item_button == null:
		var child_count: int = v_box_container.get_child_count()
		if child_count <= 0:
			return
		var first_child: Button = v_box_container.get_child(0)
		if first_child:
			last_selected_item_button = first_child
			first_child.grab_focus()
	else:
		last_selected_item_button.grab_focus()


func _focus_option_default() -> void:
	if last_selected_option != null:
		last_selected_option.grab_focus()
	else:
		option_buttons.use.grab_focus()


func use(item: Item) -> void:
	if not _can_use_outside_battle(item):
		await show_cant_use_text()
		_toggle_options_visible()
		return
	if interfaces.ui_context == Global.AccessFrom.INVENTORY:
		_toggle_options_visible()
		_toggle_visible()
		Global.switch_ui_context.emit(Global.AccessFrom.INVENTORY)
		_set_mode_use_target(true)
		Global.request_open_party.emit()
		var monster: Monster = await Global.monster_selected
		Global.use_item_on.emit(item, monster)


func give(item: Item) -> void:
	if not _can_give_to_monster(item):
		await show_cant_hold_text()
		_toggle_options_visible()
		return
	if interfaces.ui_context == Global.AccessFrom.INVENTORY:
		_toggle_options_visible()
		_toggle_visible()
		Global.switch_ui_context.emit(Global.AccessFrom.INVENTORY)
		_set_mode_give_target(true)
		Global.request_open_party.emit()
		var monster: Monster = await Global.monster_selected
		Global.give_item_to.emit(item, monster)


func show_cant_use_text() -> void:
	var ta: Array[String] = ["That item isn't usable!"]
	Global.send_text_box.emit(self, ta, true, false, false)
	await Global.text_box_complete


func show_cant_use_in_battle_text() -> void:
	var ta: Array[String] = ["That item isn't usable!"]
	Global.send_text_box.emit(self, ta, true, false, false)
	await Global.text_box_complete


func show_cant_use_in_trainer_battle_text() -> void:
	var ta: Array[String] = ["This is a trainer battle!!"]
	Global.send_text_box.emit(self, ta, true, false, false)
	await Global.text_box_complete


func show_cant_hold_text() -> void:
	var ta: Array[String] = ["That item isn't holdable!"]
	Global.send_text_box.emit(self, ta, true, false, false)
	await Global.text_box_complete
