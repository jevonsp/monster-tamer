extends Control
var processing: bool = false
var is_moving: bool = false
var is_forced_switch: bool = false
var party_ref: Array[Monster] = []
var last_selected_monster: Button = null
var last_selected_option: Button = null
var index_moving_monster: int = -1
@onready var interfaces: CanvasLayer = $".."
@onready var panels: Dictionary = {
	panel_0 = $MarginContainer/Content/GridContainer/Panel0,
	panel_1 = $MarginContainer/Content/GridContainer/Panel1,
	panel_2 = $MarginContainer/Content/GridContainer/Panel2,
	panel_3 = $MarginContainer/Content/GridContainer/Panel3,
	panel_4 = $MarginContainer/Content/GridContainer/Panel4,
	panel_5 = $MarginContainer/Content/GridContainer/Panel5,
}
@onready var options_box: VBoxContainer = $MarginContainer/Control/Options
@onready var option_buttons: Dictionary = {
	use = $MarginContainer/Control/Options/Use,
	give = $MarginContainer/Control/Options/Give,
	summary = $MarginContainer/Control/Options/Summary,
	move = $MarginContainer/Control/Options/Move,
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
		if not is_forced_switch:
			_toggle_visible()
			Global.on_party_closed.emit()
			Global.toggle_player.emit()
			get_viewport().set_input_as_handled()
	if event.is_action_pressed("no"):
		match interfaces.ui_context:
			Global.AccessFrom.INVENTORY:
				_toggle_visible()
				Global.on_party_closed.emit()
				Global.switch_ui_context.emit(Global.AccessFrom.PARTY)
				Global.request_open_inventory.emit()
				return
			Global.AccessFrom.BATTLE:
				if not is_forced_switch:
					_toggle_visible()
					Global.on_party_closed.emit()
					return
				else:
					return
		if not options_box.visible:
			_toggle_visible()
			Global.on_party_closed.emit()
			Global.request_open_menu.emit()
		else:
			_toggle_options_visible()
		get_viewport().set_input_as_handled()


func _connect_signals() -> void:
	Global.send_player_party.connect(_on_party_change)
	Global.request_open_party.connect(_toggle_visible)
	Global.request_forced_switch.connect(_on_request_forced_switch)


func _bind_buttons() -> void:
	for panel in panels:
		panels[panel].pressed.connect(_on_monster_pressed.bind(panels[panel]))
	for button in option_buttons:
		option_buttons[button].pressed.connect(_on_option_pressed.bind(option_buttons[button]))


func _on_party_change(party: Array[Monster]) -> void:
	party_ref = party
	# Set all component's actor to new monster
	for i in range(6):
		var panel = panels.keys()[i]
		if i < party.size():
			panels[panel].update_actor(party[i])
		else:
			panels[panel].update_actor(null)
	
	if last_selected_monster and last_selected_monster.actor == null:
		last_selected_monster = null
			
			
func _toggle_visible() -> void:
	visible = not visible
	processing = not processing
	if visible:
		_focus_default_monster()
		for panel in panels:
			panels[panel].player_exp_bar.active = true
	else:
		if interfaces.ui_context != Global.AccessFrom.BATTLE:
			Global.switch_ui_context.emit(Global.AccessFrom.NONE)
		for panel in panels:
			panels[panel].player_exp_bar.active = false
	if options_box.visible:
		_focus_default_option()
	
	
func _toggle_options_visible() -> void:
	options_box.visible = not options_box.visible
	if options_box.visible:
		_focus_default_option()
	else:
		_focus_default_monster()
		
		
func _focus_default_monster() -> void:
	if last_selected_monster and last_selected_monster.actor != null:
		last_selected_monster.grab_focus()
		return

	var keys := panels.keys()
	if keys.is_empty():
		return

	var first_key = keys[0]
	var panel: Button = panels[first_key]
	last_selected_monster = panel
	panel.grab_focus()


func _focus_default_option() -> void:
	if last_selected_option and last_selected_option.is_inside_tree():
		last_selected_option.grab_focus()
		return

	var keys := option_buttons.keys()
	if keys.is_empty():
		return

	var first_key = keys[0]
	var option_button: Button = option_buttons[first_key]
	last_selected_option = option_button
	option_button.grab_focus()


func _on_monster_pressed(button: Button) -> void:
	var num := int(button.name.trim_prefix("Panel"))
	last_selected_monster = button
	match interfaces.ui_context:
		Global.AccessFrom.PARTY:
			if is_moving:
				index_moving_monster = num
				stop_moving()
			else:
				_toggle_options_visible()
				index_moving_monster = num
		Global.AccessFrom.INVENTORY:
			Global.monster_selected.emit(button.actor)
			_toggle_visible()
			interfaces.ui_context = Global.AccessFrom.NONE
			Global.switch_ui_context.emit(Global.AccessFrom.INVENTORY)
			Global.request_open_inventory.emit()
		Global.AccessFrom.BATTLE:
			if not is_forced_switch:
				if num == 0:
					var ta: Array[String] = ["That monster is already fighting!"]
					Global.send_text_box.emit(null, ta, true, false, false)
					await Global.text_box_complete
					return
				Global.request_switch_creation.emit(num)
				_toggle_visible()
			else:
				var monster_selected: Monster = button.actor
				if not monster_selected.is_able_to_fight:
					var ta: Array[String] = ["That monster is not able to fight!"]
					Global.send_text_box.emit(null, ta, true, false, false)
					await Global.text_box_complete
					return
				else:
					Global.send_selected_force_switch.emit(monster_selected)
					is_forced_switch = false
					_toggle_visible()


func _on_option_pressed(button: Button) -> void:
	last_selected_option = button
	match button.name:
		"Use":
			use()
		"Give":
			give()
		"Summary":
			_open_monster_summary(last_selected_monster.actor)
		"Move":
			start_moving()
	get_viewport().set_input_as_handled()


func use() -> void:
	_toggle_options_visible()
	_toggle_visible()
	Global.switch_ui_context.emit(Global.AccessFrom.PARTY)
	Global.set_inventory_use.emit(true)
	Global.request_open_inventory.emit()
	var item = await Global.item_selected
	if item.use_effect == null:
		var ta: Array[String] = ["That item isn't usable!"]
		var toggles_player = false
		Global.send_text_box.emit(self, ta, true, false, toggles_player)
		await Global.text_box_complete
		return
	var actor: Monster = last_selected_monster.actor
	Global.use_item_on.emit(item, actor)
	
	
func give() -> void:
	_toggle_options_visible()
	_toggle_visible()
	Global.switch_ui_context.emit(Global.AccessFrom.PARTY)
	Global.set_inventory_give.emit(true)
	Global.request_open_inventory.emit()
	var item = await Global.item_selected
	if item.held_effect == null:
		var ta: Array[String] = ["That item isn't holdable!"]
		var toggles_player = false
		Global.send_text_box.emit(self, ta, true, false, toggles_player)
		await Global.text_box_complete
		return
	var actor: Monster = last_selected_monster.actor
	Global.give_item_to.emit(item, actor)


func _open_monster_summary(monster: Monster) -> void:
	Global.request_open_summary.emit(monster)
	_toggle_visible()
	Global.switch_ui_context.emit(Global.AccessFrom.PARTY)


func start_moving() -> void:
	_toggle_options_visible()
	is_moving = true
	if last_selected_monster:
		index_moving_monster = int(last_selected_monster.name.trim_prefix("Panel"))


func stop_moving() -> void:
	is_moving = false
	if not last_selected_monster:
		return

	var current_index := int(last_selected_monster.name.trim_prefix("Panel"))
	if index_moving_monster == current_index:
		return
	else:
		Global.out_of_battle_switch.emit(index_moving_monster, current_index)


func _on_request_forced_switch() -> void:
	is_forced_switch = true
	_toggle_visible()
