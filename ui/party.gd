extends Control
var processing: bool = false
@onready var panels: Dictionary = {
	panel_0 = $MarginContainer/Content/GridContainer/Panel0,
	panel_1 = $MarginContainer/Content/GridContainer/Panel1,
	panel_2 = $MarginContainer/Content/GridContainer/Panel2,
	panel_3 = $MarginContainer/Content/GridContainer/Panel3,
	panel_4 = $MarginContainer/Content/GridContainer/Panel4,
	panel_5 = $MarginContainer/Content/GridContainer/Panel5,
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
		Global.on_party_closed.emit()
		Global.toggle_player.emit()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("no"):
		_toggle_visible()
		Global.on_party_closed.emit()
		Global.request_open_menu.emit()
		get_viewport().set_input_as_handled()


func _connect_signals() -> void:
	Global.send_player_party.connect(_on_party_change)
	Global.request_open_party.connect(_toggle_visible)


func _bind_buttons() -> void:
	for panel in panels:
		panels[panel].pressed.connect(_on_monster_pressed.bind(panels[panel]))


func _on_party_change(party: Array[Monster]) -> void:
	# Set all component's actor to new monster
	for i in range(6):
		var panel = panels.keys()[i]
		if i < party.size():
			panels[panel].update_actor(party[i])
		else:
			panels[panel].update_actor(null)
			
			
func _toggle_visible() -> void:
	visible = not visible
	processing = not processing
	if visible:
		_focus_default()
		
		
func _focus_default() -> void:
	var panel = panels.keys()[0]
	panels[panel].grab_focus()


func _on_monster_pressed(button: Button) -> void:
	var num := int(button.name.trim_prefix("Panel"))
	Global.send_summary_index.emit(num)
	Global.request_open_summary.emit()
	_toggle_visible()
	
