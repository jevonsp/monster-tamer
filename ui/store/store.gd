extends Control

enum Focused { OPTION, CATEGORY, ITEM, QUANTITY }
enum Transaction { CHOOSING, BUYING, SELLING }

const STORE_PANEL = preload("uid://b301kh78bm7js")

@export var inventory: Dictionary[Item.Type, InventoryPage] = { }

var processing: bool = false
var focus_state: Focused = Focused.OPTION
var transaction_state: Transaction = Transaction.CHOOSING
var npc_inventory: Dictionary[Item.Type, InventoryPage] = { }
var player_inventory: Dictionary[Item.Type, InventoryPage] = { }
var player_ref: Player = null
var categories: int = 1
var current_category: int = 0
var last_focused_item_button: Button = null
var last_focused_option_button: Button = null
var last_focused_quantity_button: Button = null

@onready var v_box_container: VBoxContainer = $ScrollContainer/MarginContainer/VBoxContainer
@onready var options_box: VBoxContainer = $Options
@onready var category_label: Label = $CategoryLabel
@onready var quantity_box: VBoxContainer = $Quantity


func _ready() -> void:
	_connect_signals()
	_bind_buttons()
	_display_current()
	categories = inventory.size()


func _unhandled_input(event: InputEvent) -> void:
	if not processing:
		return
	match focus_state:
		Focused.OPTION:
			_option_focused_input(event)
		Focused.CATEGORY:
			_category_focused_input(event)
		Focused.ITEM:
			_item_focused_input(event)
		Focused.QUANTITY:
			_quantity_focused_input(event)


func _option_focused_input(event: InputEvent) -> void:
	if _is_action_triggered(event, "no"):
		_exit_store()


func _category_focused_input(event: InputEvent) -> void:
	if _is_action_triggered(event, "left"):
		_switch_page(Vector2.LEFT)
	if _is_action_triggered(event, "right"):
		_switch_page(Vector2.RIGHT)
	if _is_action_triggered(event, "yes"):
		_set_focus_state(Focused.ITEM)
	if _is_action_triggered(event, "no"):
		_hide_items()
		_show_options()
		_set_focus_state(Focused.OPTION)
		call_deferred("_grab_focus_for_state", Focused.OPTION)


func _item_focused_input(event: InputEvent) -> void:
	if _is_action_triggered(event, "no"):
		_set_focus_state(Focused.CATEGORY)


func _quantity_focused_input(event: InputEvent) -> void:
	if _is_action_triggered(event, "no"):
		_hide_quantity()
		_set_focus_state(Focused.ITEM)
		call_deferred("_grab_focus_for_state", Focused.ITEM)


func _is_action_triggered(event: InputEvent, action: StringName) -> bool:
	if not event.is_action_pressed(action):
		return false
	if event is InputEventKey and event.is_echo():
		return false
	get_viewport().set_input_as_handled()
	return true


func _connect_signals() -> void:
	Ui.request_open_store.connect(_display_store)


func _bind_buttons() -> void:
	var option_buttons: Array[Node] = options_box.get_children()
	for button: Button in option_buttons:
		button.pressed.connect(_on_button_pressed.bind(button))
		button.focus_entered.connect(func(): last_focused_option_button = button)

	var quantity_buttons: Array[Node] = quantity_box.get_children()
	for button: Button in quantity_buttons:
		button.pressed.connect(_on_quantity_pressed.bind(button))
		button.focus_entered.connect(func(): last_focused_quantity_button = button)


func _display_store(store_component: NPCStoreComponent) -> void:
	_toggle_visible()
	_update_inventory(store_component)
	_set_transaction_state(Transaction.CHOOSING)


func _update_inventory(store_component: NPCStoreComponent) -> void:
	npc_inventory = store_component.inventory
	player_ref = get_tree().get_first_node_in_group("player")
	if player_ref:
		player_inventory = player_ref.inventory_handler.inventory
	_set_active_inventory_for_transaction()


func _display_current() -> void:
	_clear_page()
	if inventory.is_empty():
		return
	if not inventory.has(current_category):
		var valid_keys: Array = inventory.keys()
		valid_keys.sort()
		if valid_keys.is_empty():
			return
		current_category = valid_keys[0]
	var current_page: InventoryPage = inventory[current_category]
	for item in current_page.page:
		var quantity = current_page.page[item]
		_create_item(item, quantity)
	_display_item_category()


func _display_item_category() -> void:
	category_label.text = "Category: %s" % Item.Type.keys()[current_category].to_lower().capitalize()


func _display_page(page: InventoryPage) -> void:
	_clear_page()
	for item in page.page:
		var quantity = page.page[item]
		_create_item(item, quantity)


func _create_item(item: Item, quantity: int) -> void:
	var panel: Button = STORE_PANEL.instantiate()
	v_box_container.add_child(panel)
	panel.display(item, quantity)
	panel.focus_entered.connect(func(): last_focused_item_button = panel)
	panel.pressed.connect(_on_item_pressed)


func _on_item_pressed() -> void:
	match transaction_state:
		Transaction.BUYING:
			_show_quantity()
			_set_focus_state(Focused.QUANTITY)
		Transaction.SELLING:
			_show_quantity()
			_set_focus_state(Focused.QUANTITY)
		Transaction.CHOOSING:
			return


func _on_button_pressed(button: Button) -> void:
	match button.name:
		"Buy":
			_set_transaction_state(Transaction.BUYING)
		"Sell":
			_set_transaction_state(Transaction.SELLING)

	_hide_options()
	_show_items()
	_display_current()
	_set_focus_state(Focused.CATEGORY)


func _on_quantity_pressed(button: Button) -> void:
	match transaction_state:
		Transaction.BUYING:
			match button.name:
				"One":
					_buy(1)
				"Five":
					_buy(5)
				"Ten":
					_buy(10)
		Transaction.SELLING:
			match button.name:
				"One":
					_sell(1)
				"Five":
					_sell(5)
				"Ten":
					_sell(10)

	_hide_quantity()
	_set_focus_state(Focused.ITEM)


func _clear_page() -> void:
	for child in v_box_container.get_children():
		child.queue_free()
	last_focused_item_button = null


func _switch_page(dir: Vector2) -> void:
	if inventory.is_empty():
		return
	var valid_keys: Array = inventory.keys()
	valid_keys.sort()
	if valid_keys.is_empty():
		return
	if not valid_keys.has(current_category):
		current_category = valid_keys[0]
		_display_current()
		return
	var current_index: int = valid_keys.find(current_category)
	match dir:
		Vector2.LEFT:
			current_index = (current_index - 1 + valid_keys.size()) % valid_keys.size()
		Vector2.RIGHT:
			current_index = (current_index + 1) % valid_keys.size()
	current_category = valid_keys[current_index]

	_display_current()


func _grab_item_focus() -> void:
	if last_focused_item_button:
		last_focused_item_button.grab_focus()
	else:
		var items = v_box_container.get_children()
		if items.size() > 0:
			items[0].grab_focus()


func _drop_item_focus() -> void:
	if last_focused_item_button:
		last_focused_item_button.release_focus()


func _grab_option_focus() -> void:
	if last_focused_option_button:
		last_focused_option_button.grab_focus()
	else:
		var options = options_box.get_children()
		if options.size() > 0:
			options[0].grab_focus()


func _drop_option_focus() -> void:
	if last_focused_option_button:
		last_focused_option_button.release_focus()


func _grab_category_focus() -> void:
	pass


func _drop_category_focus() -> void:
	pass


func _toggle_visible() -> void:
	visible = not visible
	processing = visible
	if visible:
		_set_focus_state(Focused.OPTION)


func _show_options() -> void:
	options_box.visible = true


func _hide_options() -> void:
	options_box.visible = false


func _show_items() -> void:
	v_box_container.visible = true
	category_label.visible = true


func _hide_items() -> void:
	v_box_container.visible = false
	category_label.visible = false


func _show_quantity() -> void:
	quantity_box.visible = true


func _hide_quantity() -> void:
	quantity_box.visible = false


func _set_focus_state(new_state: Focused) -> void:
	if new_state == focus_state:
		_grab_focus_for_state(new_state)
		return
	_drop_focus_for_state(focus_state)
	focus_state = new_state
	_grab_focus_for_state(focus_state)


func _grab_quantity_focus() -> void:
	if last_focused_quantity_button:
		last_focused_quantity_button.grab_focus()
		return
	var quantity_buttons = quantity_box.get_children()
	if quantity_buttons.size() > 0:
		quantity_buttons[0].grab_focus()


func _drop_quantity_focus() -> void:
	if last_focused_quantity_button:
		last_focused_quantity_button.release_focus()


func _grab_focus_for_state(state: Focused) -> void:
	match state:
		Focused.OPTION:
			_grab_option_focus()
		Focused.CATEGORY:
			_grab_category_focus()
		Focused.ITEM:
			_grab_item_focus()
		Focused.QUANTITY:
			_grab_quantity_focus()


func _drop_focus_for_state(state: Focused) -> void:
	match state:
		Focused.CATEGORY:
			_drop_category_focus()
		Focused.ITEM:
			_drop_item_focus()
		Focused.OPTION:
			_drop_option_focus()
		Focused.QUANTITY:
			_drop_quantity_focus()


func _set_transaction_state(new_state: Transaction) -> void:
	if new_state != transaction_state:
		transaction_state = new_state
	_set_active_inventory_for_transaction()
	match transaction_state:
		Transaction.BUYING:
			_display_current()
		Transaction.SELLING:
			_display_current()
		Transaction.CHOOSING:
			pass


func _set_active_inventory_for_transaction() -> void:
	match transaction_state:
		Transaction.BUYING:
			inventory = npc_inventory
		Transaction.SELLING:
			inventory = player_inventory
		Transaction.CHOOSING:
			inventory = npc_inventory
	_sync_category_bounds()


func _sync_category_bounds() -> void:
	categories = max(inventory.size(), 1)
	if inventory.is_empty():
		current_category = 0
		return
	if not inventory.has(current_category):
		var valid_keys: Array = inventory.keys()
		valid_keys.sort()
		current_category = valid_keys[0]


func _exit_store() -> void:
	_reset()
	_toggle_visible()


func _reset() -> void:
	focus_state = Focused.CATEGORY
	transaction_state = Transaction.CHOOSING
	categories = 1
	current_category = 0
	inventory = { }
	npc_inventory = { }
	player_inventory = { }
	player_ref = null
	_clear_page()
	_show_options()
	_hide_items()
	_hide_quantity()


func _buy(amount: int) -> void:
	var item = last_focused_item_button.item
	var r: Dictionary = StoreService.try_buy(player_ref, current_category, item, amount, inventory)
	if r.ok:
		_grab_item_focus()
		return
	var ta: Array[String] = [r.message]
	Ui.send_text_box.emit(null, ta, true, false, false)
	await Ui.text_box_complete
	_grab_item_focus()


func _sell(amount: int) -> void:
	if not player_ref:
		return
	if not last_focused_item_button:
		return
	var item: Item = last_focused_item_button.item
	var r: Dictionary = StoreService.try_sell(player_ref, player_inventory, current_category, item, amount)
	if r.ok:
		_display_current()
		_set_focus_state(Focused.ITEM)
		return
	var ta: Array[String] = [r.message]
	Ui.send_text_box.emit(null, ta, true, false, false)
	await Ui.text_box_complete
