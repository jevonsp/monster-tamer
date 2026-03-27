extends Control

enum State { DEFAULT, MOVING }

var state: State = State.DEFAULT
var processing: bool = false
var is_forced_switch: bool = false
var party_ref: Array[Monster] = []
var last_selected_monster: Button = null
var last_selected_option: Button = null
var moving_source_index: int = -1

#region Node References
@onready var interfaces: CanvasLayer = $".."
@onready var options_box: VBoxContainer = $MarginContainer/Control/Options
@onready var panels: Dictionary = {
	panel_0 = $MarginContainer/Content/GridContainer/Panel0,
	panel_1 = $MarginContainer/Content/GridContainer/Panel1,
	panel_2 = $MarginContainer/Content/GridContainer/Panel2,
	panel_3 = $MarginContainer/Content/GridContainer/Panel3,
	panel_4 = $MarginContainer/Content/GridContainer/Panel4,
	panel_5 = $MarginContainer/Content/GridContainer/Panel5,
}
@onready var option_buttons: Dictionary = {
	summary = $MarginContainer/Control/Options/Summary,
	move = $MarginContainer/Control/Options/Move,
	use = $MarginContainer/Control/Options/Use,
	give = $MarginContainer/Control/Options/Give,
	take = $MarginContainer/Control/Options/Take,
}
#region Helper Nodes
@onready var input_handler: Node = $InputHandler
@onready var visibility_focus_handler: Node = $"Visibility&FocusHandler"


func _ready() -> void:
	_connect_signals()
	_bind_buttons()
	if options_box.visible:
		options_box.visible = false
	if visible:
		processing = true
		visibility_focus_handler.focus_default_monster()


func start_moving() -> void:
	if last_selected_monster:
		moving_source_index = int(last_selected_monster.name.trim_prefix("Panel"))

	state = State.MOVING
	visibility_focus_handler.toggle_options_visible()


func stop_moving(destination_index: int) -> void:
	state = State.DEFAULT

	if moving_source_index == destination_index:
		return

	Global.out_of_battle_switch.emit(moving_source_index, destination_index)
	moving_source_index = -1


func use() -> void:
	visibility_focus_handler.toggle_options_visible()
	visibility_focus_handler.toggle_visible()
	Global.switch_ui_context.emit(Global.AccessFrom.PARTY)
	Global.set_inventory_use.emit(true)
	Global.request_open_inventory.emit()

	var item = await Global.item_selected
	if item.use_effect == null:
		Global.send_text_box.emit(self, ["That item isn't usable!"], true, false, false)
		await Global.text_box_complete
		return

	_set_item_use_processing(false, "party use started")
	Global.use_item_on.emit(item, last_selected_monster.actor)
	await Global.item_finished_using
	if not visible:
		Global.switch_ui_context.emit(Global.AccessFrom.PARTY)
		visibility_focus_handler.set_visible(true)
	_set_item_use_processing(true, "party use finished")


func give() -> void:
	visibility_focus_handler.toggle_options_visible()
	visibility_focus_handler.toggle_visible()
	Global.switch_ui_context.emit(Global.AccessFrom.PARTY)
	Global.set_inventory_give.emit(true)
	Global.request_open_inventory.emit()

	var item: Item = await Global.item_selected
	if item.held_effect == null:
		var ta: Array[String] = ["That item isn't holdable!"]
		Global.send_text_box.emit(self, ta, true, false, false)
		await Global.text_box_complete
		return

	await _give_item_to_monster(item, last_selected_monster.actor)
	Global.request_open_inventory.emit()
	Global.switch_ui_context.emit(Global.AccessFrom.PARTY)
	Global.request_open_party.emit()


func take() -> void:
	var ta: Array[String]
	var monster: Monster = last_selected_monster.actor
	var item = monster.held_item

	if item == null:
		ta = ["%s isn't holding anything." % monster.name]
		Global.send_text_box.emit(null, ta, true, false, false)
		await Global.text_box_complete
		visibility_focus_handler.focus_default_option()
		return

	ta = ["Do you want to take %s from %s" % [item.name, monster.name]]
	Global.send_text_box.emit(null, ta, false, true, false)
	var answer = await Global.answer_given
	await Global.text_box_complete

	if answer:
		monster.take_item()
		ta = ["Took the %s from %s" % [item.name, monster.name]]
		Global.send_text_box.emit(null, ta, true, false, false)
		await Global.text_box_complete

	visibility_focus_handler.focus_default_option()


func open_summary() -> void:
	Global.request_open_summary.emit(last_selected_monster.actor)
	visibility_focus_handler.set_visible(false)
	Global.switch_ui_context.emit(Global.AccessFrom.PARTY)


func _connect_signals() -> void:
	Global.send_player_party.connect(_on_party_change)
	Global.request_open_party.connect(visibility_focus_handler.toggle_visible)
	Global.request_forced_switch.connect(_on_request_forced_switch)


func _bind_buttons() -> void:
	for panel in panels:
		panels[panel].pressed.connect(input_handler._on_monster_pressed.bind(panels[panel]))
		panels[panel].focus_entered.connect(visibility_focus_handler.set_monster_focus.bind(panels[panel]))

	for button in option_buttons:
		option_buttons[button].pressed.connect(input_handler._on_option_pressed.bind(option_buttons[button]))
		option_buttons[button].focus_entered.connect(visibility_focus_handler.set_option_focus.bind(option_buttons[button]))


func _on_party_change(party: Array[Monster]) -> void:
	party_ref = party

	for i in range(6):
		var panel = panels.keys()[i]
		if i < party.size():
			panels[panel].update_actor(party[i])
		else:
			panels[panel].update_actor(null)

	if last_selected_monster and last_selected_monster.actor == null:
		last_selected_monster = null


func _on_request_forced_switch() -> void:
	is_forced_switch = true
	visibility_focus_handler.toggle_visible()


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
	Global.send_text_box.emit(
		self,
		ta,
		false,
		true,
		false,
	)
	var should_swap: bool = await Global.answer_given
	await Global.text_box_complete
	return should_swap


func _set_item_use_processing(value: bool, _reason: String) -> void:
	processing = value and visible
#endregion
