extends Control

const STORE_PANEL = preload("uid://b301kh78bm7js")

enum Focused { CATEGORY, ITEM, OPTION }
enum Transaction { BUYING, SELLING }

var focus_state: Focused = Focused.CATEGORY:
	set(value):
		focus_state = value
		print(Focused.keys()[focus_state])
var transaction_state: Transaction = Transaction.BUYING:
	set(value):
		transaction_state = value
		print(Transaction.keys()[transaction_state])

var categories: int = 1
var current_category: int = 0
@export var inventory: Dictionary[Item.Type, InventoryPage] = {}

@onready var v_box_container: VBoxContainer = $ScrollContainer/MarginContainer/VBoxContainer
@onready var options_box: VBoxContainer = $Options

var last_focused_item_button: Button = null
var last_focused_option_button: Button = null


func _ready() -> void:
	_connect_signals()
	_bind_buttons()
	_display_current()


func _unhandled_input(event: InputEvent) -> void:
	match focus_state:
		Focused.CATEGORY:
			_category_focused_input(event)
		Focused.ITEM:
			_item_focused_input(event)
		Focused.OPTION:
			_option_focused_input(event)


func _category_focused_input(event: InputEvent) -> void:
	if event.is_action_pressed("left"):
		_switch_page(Vector2.LEFT)
	if event.is_action_pressed("right"):
		_switch_page(Vector2.RIGHT)
	if event.is_action_pressed("no"):
		_exit_store()
	if event.is_action_pressed("yes"):
		_set_focus_state(Focused.ITEM)


func _item_focused_input(event: InputEvent) -> void:
	if event.is_action_pressed("no"):
		_set_focus_state(Focused.CATEGORY)


func _option_focused_input(event: InputEvent) -> void:
	if event.is_action_pressed("no"):
		_set_focus_state(Focused.ITEM)
		_toggle_options_visible()
		_grab_item_focus()


func _connect_signals() -> void:
	Global.request_open_store.connect(_display_store)


func _bind_buttons() -> void:
	var buttons: Array[Node] = options_box.get_children()
	for button: Button in buttons:
		button.pressed.connect(_on_button_pressed.bind(button))


func _display_store(store_component: NPCStoreComponent) -> void:
	_update_inventory(store_component)
	_display_current()
	_toggle_visible()


func _update_inventory(store_component: NPCStoreComponent) -> void:
	inventory = store_component.inventory
	categories = max(inventory.size(), 1)
	if current_category >= categories:
		current_category = 0


func _display_current() -> void:
	_clear_page()
	if inventory.is_empty():
		return
	var current_page: InventoryPage = inventory[current_category]
	for item in current_page.page:
		var quantity = current_page.page[item]
		_create_item(item, quantity)


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


func _clear_page() -> void:
	for child in v_box_container.get_children():
		child.queue_free()
	last_focused_item_button = null


func _switch_page(dir: Vector2) -> void:
	if inventory.is_empty():
		return
	match dir:
		Vector2.LEFT:
			current_category = int((current_category - 1 + categories) % categories)
		Vector2.RIGHT:
			current_category = int((current_category + 1) % categories)
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
		last_focused_item_button = null


func _grab_option_focus() -> void:
	if last_focused_option_button:
		last_focused_option_button.release_focus()
	else:
		pass


func _toggle_visible() -> void:
	visible = not visible


func _toggle_options_visible() -> void:
	options_box.visible = not options_box.visible
	if last_focused_option_button:
		last_focused_option_button.grab_focus()
		return
	options_box.get_children()[0].grab_focus()


func _set_focus_state(new_state: Focused) -> void:
	if new_state != focus_state:
		focus_state = new_state
	match focus_state:
		Focused.CATEGORY:
			_drop_item_focus()
		Focused.ITEM:
			_grab_item_focus()
		Focused.OPTION:
			_grab_option_focus()


func _set_transaction_state(new_state: Transaction) -> void:
	if new_state != transaction_state:
		transaction_state = new_state
	match transaction_state:
		Transaction.BUYING:
			_display_current()
		Transaction.SELLING:
			pass


func _exit_store() -> void:
	_reset()
	_toggle_visible()


func _reset() -> void:
	focus_state = Focused.CATEGORY
	categories = 1
	current_category = 0
	inventory.clear()
	_clear_page()
	if options_box.visible:
		_toggle_options_visible()


func buy() -> void:
	pass


func sell() -> void:
	pass


func _on_item_pressed() -> void:
	_toggle_options_visible()
	_set_focus_state(Focused.OPTION)


func _on_button_pressed(button: Button) -> void:
	match button.name:
		"Buy":
			if transaction_state == Transaction.BUYING:
				buy()
			else:
				_set_transaction_state(Transaction.BUYING)
		"Sell":
			if transaction_state == Transaction.SELLING:
				sell()
			else:
				_set_transaction_state(Transaction.SELLING)
