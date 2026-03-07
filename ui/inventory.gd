extends Control
const INVENTORY_PANEL = preload("uid://cq60mqy70b8je")
var processing: bool = false
var is_using: bool = false
var is_giving: bool = false
var last_focused_option: Button = null
var last_focused_button: Button = null
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
	Global.set_inventory_use.connect(_toggle_using)
	Global.set_inventory_give.connect(_toggle_giving)


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


func _on_inventory_panel_pressed(inventory_panel: Button) -> void:
	last_focused_button = inventory_panel
	var item: Item = last_focused_button.item_repr
	match interfaces.ui_context:
		Global.AccessFrom.INVENTORY:
			_toggle_options_visible()
		Global.AccessFrom.PARTY:
			if is_using and item.held_effect != null:
				await show_cant_use_text()
				return
			if is_giving and item.held_effect == null:
				await show_cant_hold_text()
				return
			if is_using and item.use_effect == null:
				await show_cant_use_text()
				return
			_toggle_visible()
			_toggle_giving(false)
			_toggle_using(false)
			Global.item_selected.emit(item)
			Global.switch_ui_context.emit(Global.AccessFrom.PARTY)
			Global.request_open_party.emit()
		Global.AccessFrom.BATTLE:
			if item.use_effect == null and item.catch_effect == null:
				await show_cant_use_in_battle_text()
				last_focused_button.grab_focus()
				return
			
			Global.add_item_to_turn_queue.emit(item)
			Global.item_used.emit(item)
			_toggle_visible()
			_toggle_giving(false)
			_toggle_using(false)


func _on_option_pressed(button: Button) -> void:
	var item: Item = last_focused_button.item_repr
	last_focused_option = button
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
		last_focused_button = null
		last_focused_option = option_buttons.use
		if interfaces.ui_context == Global.AccessFrom.PARTY:
			_toggle_giving(false)
			_toggle_using(false)
		if interfaces.ui_context != Global.AccessFrom.BATTLE:
			Global.switch_ui_context.emit(Global.AccessFrom.NONE)


func _toggle_options_visible() -> void:
	options_box.visible = not options_box.visible
	if options_box.visible:
		_focus_option_default()
	else:
		_focus_default()


func _focus_default() -> void:
	if last_focused_button == null:
		var child_count: int = v_box_container.get_child_count()
		if child_count <= 0:
			return
		var first_child: Button = v_box_container.get_child(0)
		if first_child:
			first_child.grab_focus()
	else:
		last_focused_button.grab_focus()


func _focus_option_default() -> void:
	if last_focused_option != null:
		last_focused_option.grab_focus()
	else:
		option_buttons.use.grab_focus()


func use(item: Item) -> void:
	if item.use_effect == null:
		show_cant_use_text()
		return
	if interfaces.ui_context == Global.AccessFrom.INVENTORY:
		_toggle_options_visible()
		_toggle_visible()
		Global.switch_ui_context.emit(Global.AccessFrom.INVENTORY)
		Global.request_open_party.emit()
		var monster: Monster = await Global.monster_selected
		Global.use_item_on.emit(item, monster)


func give(item: Item) -> void:
	if item.held_effect == null:
		await show_cant_hold_text()
		return
	if interfaces.ui_context == Global.AccessFrom.INVENTORY:
		_toggle_options_visible()
		_toggle_visible()
		Global.switch_ui_context.emit(Global.AccessFrom.INVENTORY)
		Global.request_open_party.emit()
		var monster: Monster = await Global.monster_selected
		Global.give_item_to.emit(item, monster)


func show_cant_use_text() -> void:
	var ta: Array[String] = ["That item isn't usable!"]
	Global.send_overworld_text_box.emit(self, ta, true, false, false)
	await Global.text_box_complete


func show_cant_use_in_battle_text() -> void:
	var ta: Array[String] = ["That item isn't usable!"]
	Global.send_battle_text_box.emit(ta, true)
	await Global.text_box_complete


func show_cant_hold_text() -> void:
	var ta: Array[String] = ["That item isn't holdable!"]
	Global.send_overworld_text_box.emit(self, ta, true, false, false)
	await Global.text_box_complete


func _toggle_using(value: bool) -> void:
	is_using = value


func _toggle_giving(value: bool) -> void:
	is_giving = value
