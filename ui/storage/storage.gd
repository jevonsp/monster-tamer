extends Control

enum State { DEFAULT, MOVING }

const PARTY_SLOT_COUNT := 6
const TOTAL_STORAGE_SLOTS := 300
const STORAGE_PAGE_COUNT := 10
const STORAGE_SLOTS_PER_PAGE := int(TOTAL_STORAGE_SLOTS / float(STORAGE_PAGE_COUNT))

var state: State = State.DEFAULT
var processing: bool = false
var party_ref: Array[Monster]
var storage_ref: Dictionary
var last_selected_monster: Button = null
var last_selected_option: Button = null
var moving_context: Dictionary = { }
var page_index: int = 0

#region Node References
@onready var grid_container: GridContainer = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer1/VBoxContainer/GridContainer
@onready var party_container: HBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer1/VBoxContainer/Party
@onready var options_container: VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/Control/Options
#region Helper Nodes
@onready var update_handler: Node = $UpdateHandler
@onready var visibility_focus_handler: Node = $"Visibility&FocusHandler"
@onready var input_handler: Node = $InputHandler


func _ready() -> void:
	_connect_signals()
	_bind_buttons()
	if options_container.visible:
		visibility_focus_handler.toggle_options_visible()
	if visible:
		processing = true
		visibility_focus_handler.focus_default_monster()


func guard_clause_deposit() -> bool:
	if party_ref.size() <= 1:
		var ta: Array[String] = ["You can't deposit your last monster!"]
		Ui.send_text_box.emit(null, ta, true, false, false)
		await Ui.text_box_complete
		return false
	return true


func start_move() -> void:
	if last_selected_monster.is_in_group("party") and last_selected_monster.actor != null:
		if not await guard_clause_deposit():
			return
		moving_context = {
			"index": _button_index(last_selected_monster),
			"from": "party",
		}
		state = State.MOVING
	elif last_selected_monster.is_in_group("storage") and last_selected_monster.actor != null:
		moving_context = {
			"index": _storage_index(last_selected_monster),
			"from": "storage",
		}
		state = State.MOVING


func cancel_move() -> void:
	moving_context = { }
	state = State.DEFAULT


func complete_move() -> void:
	if moving_context.is_empty():
		return
	match moving_context["from"]:
		"storage":
			if not last_selected_monster.is_in_group("party"):
				return
			var to_party_idx = _button_index(last_selected_monster)
			Party.request_move_storage_to_party.emit(moving_context["index"], to_party_idx)
		"party":
			if not last_selected_monster.is_in_group("storage"):
				return
			var to_storage_idx = _storage_index(last_selected_monster)
			Party.request_move_party_to_storage.emit(moving_context["index"], to_storage_idx)
	state = State.DEFAULT
	moving_context = { }


func deposit() -> void:
	if not await guard_clause_deposit():
		return
	if last_selected_monster.is_in_group("storage"):
		return
	Party.storage_deposit_monster.emit(last_selected_monster.actor)
	visibility_focus_handler.toggle_options_visible()


func withdraw() -> void:
	if last_selected_monster.is_in_group("party"):
		return
	Party.storage_withdraw_monster.emit(last_selected_monster.actor)
	visibility_focus_handler.toggle_options_visible()


func release() -> void:
	var ta: Array[String]
	var monster = last_selected_monster.actor

	if not await can_release(monster):
		visibility_focus_handler.focus_default_option()
		return

	ta = ["Do you really want to release %s? This is irreversible." % monster.name]
	Ui.send_text_box.emit(null, ta, false, true, false)

	var answer = await Ui.answer_given
	await Ui.text_box_complete

	if answer:
		ta = ["Are you absolutely sure?? YES to relase. NO to back out."]
		Ui.send_text_box.emit(null, ta, false, true, false)
		answer = await Ui.answer_given
		await Ui.text_box_complete
		if answer:
			var player = get_tree().get_first_node_in_group("player")
			await player.party_handler.remove(monster)


func can_release(monster: Monster) -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if player.party_handler.party.size() == 1 and player.party_handler.party.has(monster):
		var ta: Array[String] = ["You cant release your last monster!"]
		Ui.send_text_box.emit(null, ta, true, false, false)
		await Ui.text_box_complete
		return false

	return true
#endregion


func _bind_buttons() -> void:
	for b: Button in grid_container.get_children():
		b.focus_entered.connect(visibility_focus_handler.set_monster_focus.bind(b))
		b.pressed.connect(input_handler.on_monster_pressed.bind(b))
	for b: Button in party_container.get_children():
		b.focus_entered.connect(visibility_focus_handler.set_monster_focus.bind(b))
		b.pressed.connect(input_handler.on_monster_pressed.bind(b))
	for b: Button in options_container.get_children():
		b.focus_entered.connect(visibility_focus_handler.set_option_focus.bind(b))
		b.pressed.connect(input_handler.on_option_pressed.bind(b))


func _connect_signals() -> void:
	Party.send_player_party_and_storage.connect(_on_send_player_party_and_storage)
	Ui.request_open_storage.connect(_on_request_open_storage)


func _on_request_open_storage() -> void:
	update_handler.display_monsters()
	visibility_focus_handler.toggle_visible()


func _on_send_player_party_and_storage(party: Array[Monster], storage: Dictionary) -> void:
	party_ref = party.duplicate(true)
	storage_ref = storage.duplicate(true)
	update_handler.display_monsters()


func _button_index(button: Button) -> int:
	if button.name.begins_with("Button"):
		return button.name.trim_prefix("Button").to_int()
	return button.name.to_int()


func _storage_index(button: Button) -> int:
	return _button_index(button) + (page_index * STORAGE_SLOTS_PER_PAGE)
