extends Control
const INVENTORY_PANEL = preload("uid://cq60mqy70b8je")
var processing
@onready var v_box_container: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var options_box: VBoxContainer = $Options

func _ready() -> void:
	_connect_signals()
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
	var inventory_panel = INVENTORY_PANEL.instantiate()
	v_box_container.add_child(inventory_panel)
	inventory_panel.display(amount, item)


func _toggle_visible() -> void:
	visible = not visible
	processing = not processing


func _toggle_options_visible() -> void:
	options_box.visible = not options_box.visible
