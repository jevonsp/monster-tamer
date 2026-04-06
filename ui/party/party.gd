extends Control

enum State { DEFAULT, MOVING }

var state: State = State.DEFAULT
var processing: bool = false
var is_forced_switch: bool = false
var party_ref: Array[Monster] = []
var last_selected_monster: Button = null
var last_selected_option: Button = null
var moving_source_index: int = -1

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
	if party_ref.size() == 1:
		visibility_focus_handler.toggle_options_visible()
		return
	if last_selected_monster:
		moving_source_index = int(last_selected_monster.name.trim_prefix("Panel"))

	state = State.MOVING
	visibility_focus_handler.toggle_options_visible()


func stop_moving(destination_index: int) -> void:
	state = State.DEFAULT

	if moving_source_index == destination_index:
		return

	Party.out_of_battle_switch.emit(moving_source_index, destination_index)
	moving_source_index = -1


func use() -> void:
	visibility_focus_handler.toggle_options_visible()
	visibility_focus_handler.toggle_visible()
	Ui.switch_ui_context.emit(Global.AccessFrom.PARTY)
	Ui.set_inventory_use.emit(true)
	Ui.request_open_inventory.emit()

	var item = await Ui.item_selected
	if not ItemInteraction.can_use_outside_battle(item):
		Ui.send_text_box.emit(self, ["That item isn't usable!"], true, false, false)
		await Ui.text_box_complete
		return

	_set_item_use_processing(false, "party use started")
	Inventory.use_item_on.emit(item, last_selected_monster.actor)
	await Ui.item_finished_using
	if not visible:
		Ui.switch_ui_context.emit(Global.AccessFrom.PARTY)
		visibility_focus_handler.set_visible(true)
	_set_item_use_processing(true, "party use finished")


func give() -> void:
	visibility_focus_handler.toggle_options_visible()
	visibility_focus_handler.toggle_visible()
	Ui.switch_ui_context.emit(Global.AccessFrom.PARTY)
	Ui.set_inventory_give.emit(true)
	Ui.request_open_inventory.emit()

	var item: Item = await Ui.item_selected
	if not ItemInteraction.can_give_to_monster(item):
		var ta: Array[String] = ["That item isn't holdable!"]
		Ui.send_text_box.emit(self, ta, true, false, false)
		await Ui.text_box_complete
		return

	await ItemInteraction.give_item_to_monster(item, last_selected_monster.actor, self)
	Ui.request_open_inventory.emit()
	Ui.switch_ui_context.emit(Global.AccessFrom.PARTY)
	Ui.request_open_party.emit()


func take() -> void:
	var ta: Array[String]
	var monster: Monster = last_selected_monster.actor
	var item = monster.held_item

	if item == null:
		ta = ["%s isn't holding anything." % monster.name]
		Ui.send_text_box.emit(null, ta, true, false, false)
		await Ui.text_box_complete
		visibility_focus_handler.focus_default_option()
		return

	ta = ["Do you want to take %s from %s" % [item.name, monster.name]]
	Ui.send_text_box.emit(null, ta, false, true, false)
	var answer = await Ui.answer_given
	await Ui.text_box_complete

	if answer:
		monster.take_item()
		ta = ["Took the %s from %s" % [item.name, monster.name]]
		Ui.send_text_box.emit(null, ta, true, false, false)
		await Ui.text_box_complete

	visibility_focus_handler.focus_default_option()


func open_summary() -> void:
	Ui.request_open_summary.emit(last_selected_monster.actor)
	visibility_focus_handler.set_visible(false)
	Ui.switch_ui_context.emit(Global.AccessFrom.PARTY)


func _connect_signals() -> void:
	Party.send_player_party.connect(_on_party_change)
	Ui.request_open_party.connect(visibility_focus_handler.toggle_visible)
	Battle.request_forced_switch.connect(_on_request_forced_switch)


func _bind_buttons() -> void:
	for panel in panels:
		panels[panel].pressed.connect(input_handler.on_monster_pressed.bind(panels[panel]))
		panels[panel].focus_entered.connect(visibility_focus_handler.set_monster_focus.bind(panels[panel]))

	for button in option_buttons:
		option_buttons[button].pressed.connect(input_handler.on_option_pressed.bind(option_buttons[button]))
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


func _set_item_use_processing(value: bool, _reason: String) -> void:
	processing = value and visible
