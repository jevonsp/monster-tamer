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
	use = $MarginContainer/Control/Options/Use,
	give = $MarginContainer/Control/Options/Give,
	summary = $MarginContainer/Control/Options/Summary,
	move = $MarginContainer/Control/Options/Move,
}
#endregion

#region Helper Nodes
@onready var input_handler: Node = $InputHandler
@onready var visibility_focus_handler: Node = $"Visibility&FocusHandler"
#endregion


func _ready() -> void:
	_connect_signals()
	_bind_buttons()
	if visible:
		processing = true
		visibility_focus_handler._focus_default_monster()


func _connect_signals() -> void:
	Global.send_player_party.connect(_on_party_change)
	Global.request_open_party.connect(visibility_focus_handler._toggle_visible)
	Global.request_forced_switch.connect(_on_request_forced_switch)


func _bind_buttons() -> void:
	for panel in panels:
		panels[panel].pressed.connect(input_handler._on_monster_pressed.bind(panels[panel]))
		panels[panel].focus_entered.connect(visibility_focus_handler._set_monster_focus.bind(panels[panel]))

	for button in option_buttons:
		option_buttons[button].pressed.connect(input_handler._on_option_pressed.bind(option_buttons[button]))
		option_buttons[button].focus_entered.connect(visibility_focus_handler._set_option_focus.bind(option_buttons[button]))


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
	visibility_focus_handler._toggle_visible()


func start_moving() -> void:
	if last_selected_monster:
		moving_source_index = int(last_selected_monster.name.trim_prefix("Panel"))

	state = State.MOVING
	visibility_focus_handler._toggle_options_visible()


func stop_moving(destination_index: int) -> void:
	state = State.DEFAULT

	if moving_source_index == destination_index:
		return

	Global.out_of_battle_switch.emit(moving_source_index, destination_index)
	moving_source_index = -1


func use() -> void:
	visibility_focus_handler._toggle_options_visible()
	visibility_focus_handler._toggle_visible()
	Global.switch_ui_context.emit(Global.AccessFrom.PARTY)
	Global.set_inventory_use.emit(true)
	Global.request_open_inventory.emit()

	var item = await Global.item_selected
	if item.use_effect == null:
		Global.send_text_box.emit(self, ["That item isn't usable!"], true, false, false)
		await Global.text_box_complete
		return

	Global.use_item_on.emit(item, last_selected_monster.actor)


func give() -> void:
	visibility_focus_handler._toggle_options_visible()
	visibility_focus_handler._toggle_visible()
	Global.switch_ui_context.emit(Global.AccessFrom.PARTY)
	Global.set_inventory_give.emit(true)
	Global.request_open_inventory.emit()

	var item = await Global.item_selected
	if item.held_effect == null:
		Global.send_text_box.emit(self, ["That item isn't holdable!"], true, false, false)
		await Global.text_box_complete
		return

	Global.give_item_to.emit(item, last_selected_monster.actor)


func open_summary() -> void:
	Global.request_open_summary.emit(last_selected_monster.actor)
	visibility_focus_handler._toggle_visible()
	Global.switch_ui_context.emit(Global.AccessFrom.PARTY)
