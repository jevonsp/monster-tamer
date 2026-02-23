extends Control
const INVENTORY_PANEL = preload("uid://cq60mqy70b8je")
var processing: bool = false
var last_focused_option: Button = null
var last_focused_button: Button = null
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
		_toggle_visible()
		Global.on_inventory_closed.emit()
		Global.toggle_player.emit()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("no"):
		if not options_box.visible:
			_toggle_visible()
			Global.on_inventory_closed.emit()
			Global.request_open_menu.emit()
		else:
			_toggle_options_visible()
		get_viewport().set_input_as_handled()

func _bind_buttons() -> void:
	for button in option_buttons:
		option_buttons[button].pressed.connect(_on_option_pressed.bind(option_buttons[button]))


func _connect_signals() -> void:
	Global.send_player_inventory.connect(_on_inventory_change)
	Global.request_open_inventory.connect(_toggle_visible)


func _on_inventory_change(inventory: Dictionary[Item, int]) -> void:
	clear_inventory_display()
	for entry in inventory.keys():
		_create_item(inventory[entry], entry)


func clear_inventory_display() -> void:
	for child in v_box_container.get_children():
		child.queue_free()


func _create_item(amount: int, item: Item):
	var inventory_panel: Button = INVENTORY_PANEL.instantiate()
	v_box_container.add_child(inventory_panel)
	inventory_panel.display(amount, item)
	inventory_panel.pressed.connect(_on_inventory_panel_pressed.bind(inventory_panel))


func _on_inventory_panel_pressed(inventory_panel: Button) -> void:
	last_focused_button = inventory_panel
	_toggle_options_visible()
		
		
func _on_option_pressed(button: Button) -> void:
	var item = last_focused_button.item_repr
	last_focused_option = button
	match button.name:
		"Use":
			print("Use")
			use(item)
		"Give":
			print("Give")
			give(item)


func _toggle_visible() -> void:
	visible = not visible
	processing = not processing
	_focus_default()
	if not visible:
		last_focused_button = null
		last_focused_option = option_buttons.use
		


func _toggle_options_visible() -> void:
	options_box.visible = not options_box.visible
	if options_box.visible:
		_focus_option_default()
	else:
		_focus_default()


func _focus_default() -> void:
	if last_focused_button == null:
		var child_count = v_box_container.get_child_count()
		if child_count <= 0:
			return
		var first_child = v_box_container.get_child(0)
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
	if not item.is_usable:
		var ta: Array[String] = ["That item isn't usable!"]
		Global.send_overworld_text_box.emit(self, ta, true, false)
		await Global.overworld_text_box_complete
		return
	_toggle_options_visible()
	_toggle_visible()
	Global.request_access_party_from_inventory.emit()
	Global.request_open_party.emit()
	var monster = await Global.monster_selected
	print("would use %s on %s" % [item.name, monster.name])


func give(item: Item) -> void:
	if not item.is_held:
		var ta: Array[String] = ["That item isn't holdable!"]
		Global.send_overworld_text_box.emit(self, ta, true, false)
		await Global.overworld_text_box_complete
		return
	_toggle_options_visible()
	_toggle_visible()
	Global.request_access_party_from_inventory.emit()
	Global.request_open_party.emit()
	var monster = await Global.monster_selected
	print("would give %s to %s" % [item.name, monster.name])
