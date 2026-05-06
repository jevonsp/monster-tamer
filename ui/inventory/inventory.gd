extends Control

enum Focused { CATEGORY, ITEM, OPTION }
enum Mode { BROWSING, PICK_USE_TARGET, PICK_GIVE_TARGET }

const ITEM_ROW_PANEL = preload("res://ui/item_row/item_row_panel.tscn")

@export var inventory: Dictionary[Item.Type, InventoryPage] = { }

var focus_state: Focused = Focused.CATEGORY:
	set(value):
		focus_state = value
var processing: bool = false
var mode: Mode = Mode.BROWSING
var is_trainer_battle: bool = false
var last_selected_option: Button = null
var last_selected_item_button: Button = null
var _is_registered_with_ui_flow: bool = false
var categories: int = 1
var current_category: int = 0
var _category_types: Array[Item.Type] = []

@onready var interfaces: CanvasLayer = $".."
@onready var v_box_container: VBoxContainer = $ScrollContainer/MarginContainer/VBoxContainer
@onready var options_box: VBoxContainer = $Options
@onready var option_buttons: Dictionary = {
	use = $Options/Use,
	give = $Options/Give,
}
@onready var category_label: Label = $Panel/MarginContainer/CategoryLabel
@onready var money_label: Label = $CurrencyPanel/MarginContainer/MoneyLabel


func _ready() -> void:
	_connect_signals()
	_bind_buttons()
	if visible:
		_toggle_visible()


func _exit_tree() -> void:
	_sync_world_input_block(false)


func _unhandled_input(event: InputEvent) -> void:
	if not processing:
		return
	if event.is_action_pressed("menu"):
		_exit_inventory()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("no"):
		match focus_state:
			Focused.OPTION:
				_set_focus_state(Focused.ITEM)
				if options_box.visible:
					_toggle_options_visible()
			Focused.ITEM:
				_set_focus_state(Focused.CATEGORY)
			Focused.CATEGORY:
				_exit_inventory()
		get_viewport().set_input_as_handled()
		return
	match focus_state:
		Focused.CATEGORY:
			_category_focused_input(event)
		Focused.ITEM:
			_item_focused_input(event)
		Focused.OPTION:
			_option_focused_input(event)


func use(item: Item) -> void:
	if not ItemInteraction.can_use_outside_battle(item):
		await show_cant_use_text()
		_toggle_options_visible()
		return
	if interfaces.ui_context == Global.AccessFrom.INVENTORY:
		_toggle_options_visible()
		_toggle_visible()
		Ui.switch_ui_context.emit(Global.AccessFrom.INVENTORY)
		_set_mode_use_target(true)
		Ui.request_open_party.emit()
		var monster: Monster = await Ui.monster_selected
		Ui.request_open_party.emit()

		await ItemInteraction.use_item_on_monster_after_party_pick(item, monster)
		Ui.switch_ui_context.emit(Global.AccessFrom.INVENTORY)
		Ui.request_open_inventory.emit()


func give(item: Item) -> void:
	if not ItemInteraction.can_give_to_monster(item):
		await show_cant_hold_text()
		_toggle_options_visible()
		return
	if interfaces.ui_context == Global.AccessFrom.INVENTORY:
		_toggle_options_visible()
		_toggle_visible()
		Ui.switch_ui_context.emit(Global.AccessFrom.INVENTORY)
		_set_mode_give_target(true)
		Ui.request_open_party.emit()
		var monster: Monster = await Ui.monster_selected
		await ItemInteraction.give_item_to_monster(item, monster, self)
		Ui.request_open_party.emit()
		Ui.switch_ui_context.emit(Global.AccessFrom.INVENTORY)
		Ui.request_open_inventory.emit()


func show_cant_use_text() -> void:
	var ta: Array[String] = ["That item isn't usable!"]
	Ui.send_text_box.emit(self, ta, true, false, false)
	await Ui.text_box_complete


func show_cant_use_in_battle_text() -> void:
	var ta: Array[String] = ["That item isn't usable!"]
	Ui.send_text_box.emit(self, ta, true, false, false)
	await Ui.text_box_complete


func show_cant_use_in_trainer_battle_text() -> void:
	var ta: Array[String] = ["This is a trainer battle!!"]
	Ui.send_text_box.emit(self, ta, true, false, false)
	await Ui.text_box_complete


func show_cant_hold_text() -> void:
	var ta: Array[String] = ["That item isn't holdable!"]
	Ui.send_text_box.emit(self, ta, true, false, false)
	await Ui.text_box_complete


func _category_focused_input(event: InputEvent) -> void:
	if mode != Mode.BROWSING or options_box.visible:
		return
	if event.is_action_pressed("left"):
		_switch_page(Vector2.LEFT)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("right"):
		_switch_page(Vector2.RIGHT)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("yes"):
		_set_focus_state(Focused.ITEM)
		get_viewport().set_input_as_handled()
		return


func _item_focused_input(event: InputEvent) -> void:
	if mode != Mode.BROWSING or options_box.visible:
		return
	if event.is_action_pressed("left"):
		_switch_page(Vector2.LEFT)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("right"):
		_switch_page(Vector2.RIGHT)
		get_viewport().set_input_as_handled()
		return


func _option_focused_input(_event: InputEvent) -> void:
	pass


func _set_focus_state(new_state: Focused) -> void:
	if new_state != focus_state:
		focus_state = new_state
	match focus_state:
		Focused.CATEGORY:
			pass
		Focused.ITEM:
			_focus_default()
		Focused.OPTION:
			_focus_option_default()


func _exit_inventory() -> void:
	if interfaces.ui_context == Global.AccessFrom.BATTLE:
		_toggle_visible()
		Ui.on_inventory_closed.emit()
		return
	if interfaces.ui_context == Global.AccessFrom.PARTY:
		_toggle_visible()
		Ui.switch_ui_context.emit(Global.AccessFrom.PARTY)
		Ui.request_open_party.emit()
		return
	_toggle_visible()
	Ui.on_inventory_closed.emit()
	if not PlayerContext3D.player.in_battle:
		Ui.on_menu_closed.emit()
	interfaces.ui_context = Global.AccessFrom.NONE


func _bind_buttons() -> void:
	for button in option_buttons:
		option_buttons[button].pressed.connect(_on_option_pressed.bind(option_buttons[button]))


func _connect_signals() -> void:
	Inventory.send_player_inventory.connect(_on_inventory_change)
	Ui.request_open_inventory.connect(_toggle_visible)
	Ui.set_inventory_use.connect(_set_mode_use_target)
	Ui.set_inventory_give.connect(_set_mode_give_target)
	Battle.trainer_battle_requested.connect(func(_trainer): is_trainer_battle = true)
	Battle.battle_ended.connect(func(_enemy_trainer: Trainer3D) -> void: is_trainer_battle = false)


func _on_inventory_change(new_inventory: Dictionary[Item.Type, InventoryPage]) -> void:
	_update_inventory(new_inventory)
	_update_current_items()
	_update_currency_panel()


func _update_inventory(new_inventory: Dictionary[Item.Type, InventoryPage]) -> void:
	inventory = new_inventory
	_category_types.clear()
	for k in inventory.keys():
		_category_types.append(k)
	_category_types.sort()
	categories = max(_category_types.size(), 1)
	if current_category >= categories:
		current_category = 0


func _update_current_items() -> void:
	_clear_page()
	if inventory.is_empty() or _category_types.is_empty():
		return
	var item_type: Item.Type = _category_types[current_category]
	var current_page: InventoryPage = inventory[item_type]
	for item in current_page.page:
		var quantity: int = current_page.page[item]
		_create_item(item, quantity)
	_display_item_category()


func _update_currency_panel() -> void:
	var money = PlayerContext3D.inventory_handler.money
	money_label.text = "%s <- Money" % [money]


func _clear_page() -> void:
	for child in v_box_container.get_children():
		child.queue_free()
	last_selected_item_button = null


func _switch_page(dir: Vector2) -> void:
	if inventory.is_empty():
		return
	match dir:
		Vector2.LEFT:
			current_category = int((current_category - 1 + categories) % categories)
		Vector2.RIGHT:
			current_category = int((current_category + 1) % categories)
	_update_current_items()
	if focus_state == Focused.ITEM:
		_focus_default()


func _display_item_category() -> void:
	if _category_types.is_empty():
		return
	var item_type: Item.Type = _category_types[current_category]
	category_label.text = "Category -> %s" % _item_type_display_name(item_type)


func _item_type_display_name(t: Item.Type) -> String:
	for key in Item.Type.keys():
		if Item.Type[key] == t:
			return String(key).to_lower().capitalize()
	return ""


func _create_item(item: Item, quantity: int) -> void:
	var inventory_panel: Button = ITEM_ROW_PANEL.instantiate()
	v_box_container.add_child(inventory_panel)
	inventory_panel.display(item, quantity, false)
	inventory_panel.pressed.connect(_on_inventory_panel_pressed.bind(inventory_panel))


func _set_item_focus(inventory_panel: Button) -> void:
	last_selected_item_button = inventory_panel


func _set_mode_use_target(value: bool) -> void:
	mode = Mode.PICK_USE_TARGET if value else Mode.BROWSING


func _set_mode_give_target(value: bool) -> void:
	mode = Mode.PICK_GIVE_TARGET if value else Mode.BROWSING


func is_waiting_for_party_target() -> bool:
	return not visible and (mode == Mode.PICK_USE_TARGET or mode == Mode.PICK_GIVE_TARGET)


func _on_inventory_panel_pressed(inventory_panel: Button) -> void:
	_set_item_focus(inventory_panel)
	var item: Item = inventory_panel.item
	match interfaces.ui_context:
		Global.AccessFrom.INVENTORY:
			_set_focus_state(Focused.OPTION)
			_toggle_options_visible()
		Global.AccessFrom.PARTY:
			match mode:
				Mode.PICK_GIVE_TARGET:
					if not ItemInteraction.can_give_to_monster(item):
						await show_cant_hold_text()
						return
				Mode.PICK_USE_TARGET:
					if not ItemInteraction.can_use_outside_battle(item):
						await show_cant_use_text()
						return
				_:
					if not ItemInteraction.can_use_outside_battle(item):
						await show_cant_use_text()
						return
			_toggle_visible()
			mode = Mode.BROWSING
			Ui.item_selected.emit(item)
			Ui.switch_ui_context.emit(Global.AccessFrom.PARTY)
			Ui.request_open_party.emit()
		Global.AccessFrom.BATTLE:
			var reason := ItemInteraction.battle_item_blocked_reason(item, is_trainer_battle)
			if reason == "cant_use":
				await show_cant_use_in_battle_text()
				last_selected_item_button.grab_focus()
				return
			if reason == "trainer_catch":
				await show_cant_use_in_trainer_battle_text()
				last_selected_item_button.grab_focus()
				return
			Battle.enqueue_item_choice(item)
			await Battle.resolve_queued_turn()
			Inventory.item_used.emit(item)
			_toggle_visible()
			mode = Mode.BROWSING


func _on_option_pressed(button: Button) -> void:
	if last_selected_item_button == null:
		return
	var item: Item = last_selected_item_button.item
	last_selected_option = button
	match button.name:
		"Use":
			use(item)
		"Give":
			give(item)


func _toggle_visible() -> void:
	visible = not visible
	processing = visible
	_sync_world_input_block(visible)
	_set_focus_state(Focused.CATEGORY)
	last_selected_item_button = null
	if not visible:
		last_selected_item_button = null
		last_selected_option = option_buttons.use
		mode = Mode.BROWSING
		focus_state = Focused.CATEGORY
		options_box.visible = false
		if interfaces.ui_context != Global.AccessFrom.BATTLE:
			Ui.switch_ui_context.emit(Global.AccessFrom.NONE)


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


func _sync_world_input_block(should_block: bool) -> void:
	if UiFlow == null:
		return
	if should_block:
		if _is_registered_with_ui_flow:
			return
		UiFlow.register_ui_layer(self, true)
		_is_registered_with_ui_flow = true
		return
	if not _is_registered_with_ui_flow:
		return
	UiFlow.unregister_ui_layer(self)
	_is_registered_with_ui_flow = false
