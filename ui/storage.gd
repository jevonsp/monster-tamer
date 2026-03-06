extends Control
enum State {DEFAULT, MOVING}
var state: State = State.DEFAULT
var processing: bool = false

var party_ref: Array[Monster]
var storage_ref: Dictionary

var storage_global_index: int = 0
var storage_monster_index: int = 0
var storage_page_index: int = 0

var last_selected_monster: Button = null
var last_selected_option: Button = null

var monster_hovering: Dictionary = {}

@onready var grid_container: GridContainer = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer1/VBoxContainer/GridContainer
@onready var party: HBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer1/VBoxContainer/Party
@onready var options: VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/Control/Options

func _ready() -> void:
	_connect_signals()
	_bind_buttons()
	_toggle_options_visible()
	
	
func _input(event: InputEvent) -> void:
	if not processing:
		return
	if event.is_action_pressed("left") and storage_monster_index % 6 == 0:
		move_page(Vector2.LEFT)
	if event.is_action_pressed("right") and storage_monster_index % 6 == 5:
		move_page(Vector2.RIGHT)
	if event.is_action_pressed("no") and options.visible:
		_toggle_options_visible()
	elif event.is_action_pressed("no") and not options.visible:
		accept_event()
	
	
func _bind_buttons() -> void:
	for b: Button in grid_container.get_children():
		b.focus_entered.connect(_update_monster_index.bind(b))
		b.focus_entered.connect(_update_monster_index_storage.bind(b))
		b.pressed.connect(_on_monster_pressed.bind(b))
	for b: Button in party.get_children():
		b.pressed.connect(_on_monster_pressed.bind(b))
		b.focus_entered.connect(_update_monster_index_party.bind(b))
	for b: Button in options.get_children():
		b.pressed.connect(_on_option_pressed.bind(b))
	
	
func _connect_signals() -> void:
	Global.send_player_party.connect(_on_send_player_party)
	Global.send_player_storage.connect(_on_send_player_storage)
	Global.request_open_storage.connect(_on_request_open_storage)
	
	
func _on_request_open_storage() -> void:
	_toggle_visible()
	
	
func _toggle_visible() -> void:
	visible = not visible
	processing = not processing
	if visible:
		_focus_default_monster()
	else:
		last_selected_monster = null
		last_selected_option = null


func _toggle_options_visible() -> void:
	if last_selected_option != null:
		last_selected_option.release_focus()
	options.visible = not options.visible
	if options.visible:
		_focus_default_option()
	else:
		_focus_default_monster()


func _focus_default_monster() -> void:
	# INFO I do not know why this call must be deferred. It does not work otherwise.
	var target
	if last_selected_monster:
		target = last_selected_monster
	else:
		target = grid_container.get_child(max(storage_monster_index, 0))
	target.call_deferred("grab_focus")


func _set_monster_focus(button: Button) -> void:
	last_selected_monster = button


func _focus_default_option() -> void:
	if last_selected_option == null:
		var first_button = options.get_child(0)
		first_button.grab_focus()
	else:
		last_selected_option.grab_focus()


func _update_monster_index(button) -> void:
	var idx = button.name.to_int()
	if storage_monster_index == idx:
		return
	storage_monster_index = idx
	update_global_index()
	
	
func _update_monster_index_party(button) -> void:
	var idx = button.name.to_int()
	if idx >= party_ref.size():
		monster_hovering = {
			"monster": null,
			"context": party_ref
		}
		print(monster_hovering["monster"])
		return
	monster_hovering = {
		"monster": party_ref[button.name.to_int()],
		"context": party_ref
	}
	print(monster_hovering["monster"])


func _update_monster_index_storage(_button) -> void:
	if storage_ref:
		monster_hovering = {
			"monster": storage_ref[storage_global_index],
			"context": storage_ref
		}
		print(monster_hovering["monster"])


func update_global_index() -> void:
	storage_global_index = storage_page_index * 30 + storage_monster_index


func _on_monster_pressed(button: Button) -> void:
	match state:
		State.DEFAULT:
			_toggle_options_visible()
		State.MOVING:
			if button.is_in_group("storage"):
				print("storage")
			if button.is_in_group("party"):
				print("party")


func move_page(dir: Vector2) -> void:
	print("moving page: ", dir)
	match dir:
		Vector2.RIGHT:
			storage_page_index = (storage_page_index + 1) % 10
		Vector2.LEFT:
			storage_page_index = posmod(storage_page_index - 1, 10)
	update_global_index()


func _on_send_player_party(p: Array[Monster]) -> void:
	for b: Button in party.get_children():
		b.update(null)
	for idx in range(len(p)):
		party.get_child(idx).update(p[idx])
	party_ref = p.duplicate()


func _on_send_player_storage(storage: Dictionary) -> void:
	display_page(storage)
	storage_ref = storage.duplicate(true)


func display_page(storage) -> void:
	var party_starting_index = storage_global_index
	for i in range(30):
		var target = storage[party_starting_index + i]
		var button = grid_container.get_child(party_starting_index + i)
		button.update(target)
	
	
func _on_option_pressed(button) -> void:
	match button.name:
		"Move":
			initiate_move()
		"Withdraw":
			initiate_withdraw()
		"Deposit":
			initiate_deposit()
		"Release":
			pass


func initiate_move() -> void:
	if monster_hovering == null:
		printerr("no monster_hovering somehow")
		return
	if monster_hovering["monster"] == null:
		print("nothing hovered")
		return
	print("would move: ", monster_hovering["monster"])
	_toggle_options_visible()
	state = State.MOVING
	
	
func initiate_withdraw() -> void:
	if monster_hovering == null:
		printerr("no monster_hovering somehow")
		return
	if monster_hovering["monster"] == null:
		print("nothing hovered")
		return
	if monster_hovering["context"] is Array:
		print("cant withdraw a monster already in party")
		return
	print("would withdraw: ", monster_hovering["monster"], " context = Dict")
	
	
func initiate_deposit() -> void:
	if monster_hovering == null:
		printerr("no monster_hovering somehow")
		return
	if monster_hovering["monster"] == null:
		print("nothing hovered")
		return
	if monster_hovering["context"] is Dictionary:
		print("cant deposit a monster already in storage")
		return
	print("would deposit: ", monster_hovering["monster"], " context = Array")
