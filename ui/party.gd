extends Control
var processing: bool = false
var is_moving: bool = false
var is_forced_switch: bool = false
var last_focused_monster: int = -1
var last_focused_option: int = -1
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
	# Set all component's actor to new monster
	for i in range(6):
		var panel = panels.keys()[i]
		if i < party.size():
			panels[panel].update_actor(party[i])
		else:
			panels[panel].update_actor(null)
			
	if last_focused_monster > party.size():
		last_focused_monster = -1
			
			
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
	var panel_key
	if last_focused_monster == -1:
		panel_key = panels.keys()[0]
	else:
		panel_key = panels.keys()[last_focused_monster]
		
	var panel = panels[panel_key]
	
	panel.grab_focus()


func _focus_default_option() -> void:
	var option
	if last_focused_option == -1:
		option = option_buttons.keys()[0]
	else:
		option = option_buttons.keys()[last_focused_option]
	option_buttons[option].grab_focus()


func _on_monster_pressed(button: Button) -> void:
	var num := int(button.name.trim_prefix("Panel"))
	match interfaces.ui_context:
		Global.AccessFrom.PARTY:
			if is_moving:
				last_focused_monster = num
				stop_moving()
			else:
				_toggle_options_visible()
				last_focused_monster = num
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
	var index_map := {"Use": 0, "Give": 1, "Summary": 2, "Move": 3}
	if button.name in index_map:
		last_focused_option = index_map[button.name]
	match button.name:
		"Use":
			use()
		"Give":
			print_debug("Give not implemented")
			give()
		"Summary":
			_open_monster_summary(last_focused_monster)
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
	var actor = panels.values()[last_focused_monster].actor
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
	var actor = panels.values()[last_focused_monster].actor
	Global.give_item_to.emit(item, actor)


func _open_monster_summary(index: int) -> void:
	Global.send_summary_index.emit(index)
	Global.request_open_summary.emit()
	_toggle_visible()
	Global.switch_ui_context.emit(Global.AccessFrom.PARTY)


func start_moving() -> void:
	_toggle_options_visible()
	is_moving = true
	index_moving_monster = last_focused_monster


func stop_moving() -> void:
	is_moving = false
	if index_moving_monster == last_focused_monster:
		return
	else:
		Global.out_of_battle_switch.emit(index_moving_monster, last_focused_monster)


func _on_request_forced_switch() -> void:
	is_forced_switch = true
	_toggle_visible()
