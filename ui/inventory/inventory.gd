extends Control

enum Focused { CATEGORY, ITEM, OPTION }
enum Mode { BROWSING, PICK_USE_TARGET, PICK_GIVE_TARGET }

const INVENTORY_PANEL = preload("uid://cq60mqy70b8je")

@export var inventory: Dictionary[Item.Type, InventoryPage] = { }

var focus_state: Focused = Focused.CATEGORY:
	set(value):
		focus_state = value
var processing: bool = false
var mode: Mode = Mode.BROWSING
var is_trainer_battle: bool = false
var last_selected_option: Button = null
var last_selected_item_button: Button = null
var categories: int = 1
var current_category: int = 0

@onready var interfaces: CanvasLayer = $".."
@onready var v_box_container: VBoxContainer = $ScrollContainer/MarginContainer/VBoxContainer
@onready var options_box: VBoxContainer = $Options
@onready var option_buttons: Dictionary = {
	use = $Options/Use,
	give = $Options/Give,
}
@onready var category_label: Label = $CategoryLabel


func _ready() -> void:
	_connect_signals()
	_bind_buttons()
	if visible:
		_toggle_visible()


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
		Global.request_open_party.emit()
		Global.use_item_on.emit(item, monster)
		await Global.item_finished_using
		Global.switch_ui_context.emit(Global.AccessFrom.INVENTORY)
		Global.request_open_inventory.emit()


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
		await _give_item_to_monster(item, monster)
		Global.request_open_party.emit()
		Global.switch_ui_context.emit(Global.AccessFrom.INVENTORY)
		Global.request_open_inventory.emit()


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
		Global.on_inventory_closed.emit()
		return
	if interfaces.ui_context == Global.AccessFrom.PARTY:
		_toggle_visible()
		Global.switch_ui_context.emit(Global.AccessFrom.PARTY)
		Global.request_open_party.emit()
		return
	_toggle_visible()
	Global.on_inventory_closed.emit()
	Global.toggle_player.emit()
	if interfaces.ui_context == Global.AccessFrom.MENU:
		Global.request_open_menu.emit()
	interfaces.ui_context = Global.AccessFrom.NONE


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


func _on_inventory_change(new_inventory: Dictionary[Item.Type, InventoryPage]) -> void:
	_update_inventory(new_inventory)
	_display_current()


func _update_inventory(new_inventory: Dictionary[Item.Type, InventoryPage]) -> void:
	inventory = new_inventory
	categories = max(inventory.size(), 1)
	if current_category >= categories:
		current_category = 0


func _display_current() -> void:
	_clear_page()
	if inventory.is_empty():
		return
	if not inventory.has(current_category):
		return
	var current_page: InventoryPage = inventory[current_category]
	for item in current_page.page:
		var quantity: int = current_page.page[item]
		_create_item(item, quantity)
	_display_item_category()


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
	_display_current()
	if focus_state == Focused.ITEM:
		_focus_default()


func _display_item_category() -> void:
	category_label.text = "Category: %s" % Item.Type.keys()[current_category].to_lower().capitalize()


func _create_item(item: Item, quantity: int) -> void:
	var inventory_panel: Button = INVENTORY_PANEL.instantiate()
	v_box_container.add_child(inventory_panel)
	inventory_panel.display(quantity, item)
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
	mode = Mode.PICK_USE_TARGET if value else Mode.BROWSING


func _set_mode_give_target(value: bool) -> void:
	mode = Mode.PICK_GIVE_TARGET if value else Mode.BROWSING


func _on_inventory_panel_pressed(inventory_panel: Button) -> void:
	_set_item_focus(inventory_panel)
	var item: Item = inventory_panel.item_repr
	match interfaces.ui_context:
		Global.AccessFrom.INVENTORY:
			_set_focus_state(Focused.OPTION)
			_toggle_options_visible()
		Global.AccessFrom.PARTY:
			match mode:
				Mode.PICK_GIVE_TARGET:
					if not _can_give_to_monster(item):
						await show_cant_hold_text()
						return
					Global.item_selected.emit(item)
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
			mode = Mode.BROWSING
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
			mode = Mode.BROWSING


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
	_set_focus_state(Focused.CATEGORY)
	last_selected_item_button = null
	if not visible:
		last_selected_item_button = null
		last_selected_option = option_buttons.use
		mode = Mode.BROWSING
		focus_state = Focused.CATEGORY
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


func _give_item_to_monster(item: Item, monster: Monster) -> void:
	if monster == null:
		return

	if monster.hold_item(item):
		Global.give_item_to.emit(item, monster)
		await _show_item_given_text(item, monster)
		return

	if not await _confirm_item_swap(monster):
		return

	monster.swap_items(item)
	Global.give_item_to.emit(item, monster)
	await _show_item_given_text(item, monster)


func _show_item_given_text(item: Item, monster: Monster) -> void:
	var ta: Array[String] = ["Gave %s to %s to hold." % [item.name, monster.name]]
	Global.send_text_box.emit(self, ta, false, false, false)
	await Global.text_box_complete


func _confirm_item_swap(monster: Monster) -> bool:
	var held_item_name: String = monster.held_item.name if monster.held_item != null else "that item"
	var ta: Array[String] = ["%s is already holding %s. Swap items?" % [monster.name, held_item_name]]
	Global.send_text_box.emit(self, ta, false, true, false)
	var should_swap: bool = await Global.answer_given
	await Global.text_box_complete
	return should_swap
