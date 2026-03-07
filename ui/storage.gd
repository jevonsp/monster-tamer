extends Control
enum State {DEFAULT, MOVING}
var state: State = State.DEFAULT
var processing: bool = false
var party_ref: Array[Monster]
var storage_ref: Dictionary
var last_selected_monster: Button = null
var last_selected_option: Button = null
var moving_context: Dictionary = {}
var page_index: int = 0

#region Node References
@onready var grid_container: GridContainer = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer1/VBoxContainer/GridContainer
@onready var party_container: HBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer1/VBoxContainer/Party
@onready var options_container: VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/Control/Options
#endregion

#region Helper Nodes
@onready var update_handler: Node = $UpdateHandler
@onready var visiblity_focus_handler: Node = $"Visiblity&FocusHandler"
@onready var input_handler: Node = $InputHandler
#endregion


func _ready() -> void:
	_connect_signals()
	_bind_buttons()
	visiblity_focus_handler._toggle_options_visible()
	if visible:
		processing = true
		visiblity_focus_handler._focus_default_monster()
	
	
func _bind_buttons() -> void:
	for b: Button in grid_container.get_children():
		b.focus_entered.connect(visiblity_focus_handler._set_monster_focus.bind(b))
		b.pressed.connect(input_handler._on_monster_pressed.bind(b))
	for b: Button in party_container.get_children():
		b.focus_entered.connect(visiblity_focus_handler._set_monster_focus.bind(b))
		b.pressed.connect(input_handler._on_monster_pressed.bind(b))
	for b: Button in options_container.get_children():
		b.focus_entered.connect(visiblity_focus_handler._set_option_focus.bind(b))
		b.pressed.connect(input_handler._on_option_pressed.bind(b))
	
	
func _connect_signals() -> void:
	Global.send_player_party_and_storage.connect(_on_send_player_party_and_storage)
	Global.request_open_storage.connect(_on_request_open_storage)
	
	
func _on_request_open_storage() -> void:
	update_handler.display_monsters()
	visiblity_focus_handler._toggle_visible()


func _on_send_player_party_and_storage(party: Array[Monster], storage: Dictionary) -> void:
	party_ref = party.duplicate(true)
	storage_ref = storage.duplicate(true)
	update_handler.display_monsters()


func guard_clause_deposit() -> bool:
	if party_ref.size() <= 1:
		var ta: Array[String] = ["You can't deposit your last monster!"]
		Global.send_overworld_text_box.emit(null, ta, true, false, false)
		await Global.text_box_complete
		return false
	return true


func start_move() -> void:
	if last_selected_monster.is_in_group("party") and last_selected_monster.actor != null:
		if not await guard_clause_deposit():
			return
		moving_context = {
			"index": last_selected_monster.name.to_int(),
			"from": "party",
		}
		state = State.MOVING
	elif last_selected_monster.is_in_group("storage") and last_selected_monster.actor != null:
		moving_context = {
			"index": last_selected_monster.name.to_int(),
			"from": "storage",
		}
		state = State.MOVING


func complete_move() -> void:
	var to_idx = last_selected_monster.name.to_int()
	match moving_context["from"]:
		"storage":
			Global.request_move_storage_to_party.emit(moving_context["index"], to_idx)
		"party":
			Global.request_move_party_to_storage.emit(moving_context["index"], to_idx)
	state = State.DEFAULT
	moving_context = {}
	
	
func deposit() -> void:
	if not await guard_clause_deposit():
		return
	if last_selected_monster.is_in_group("storage"):
		return
	Global.storage_deposit_monster.emit(last_selected_monster.actor)
	visiblity_focus_handler._toggle_options_visible()
	
	
func withdraw() -> void:
	if last_selected_monster.is_in_group("party"):
		return
	Global.storage_withdraw_monster.emit(last_selected_monster.actor)
	visiblity_focus_handler._toggle_options_visible()
