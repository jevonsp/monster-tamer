extends CanvasLayer

var ui_context: Global.AccessFrom = Global.AccessFrom.NONE

@onready var menu: Control = $Menu
@onready var party: Control = $Party
@onready var summary: Control = $Summary
@onready var inventory: Control = $Inventory
@onready var battle: Control = $Battle
@onready var storage: Control = $Storage
@onready var store: Control = $Store
@onready var evolution_screen: Control = $EvolutionScreen
@onready var overworld_text_box: Control = $OverworldTextBox
@onready var player: Player = $"../Player"

var _blocking_ui: Array[Control] = []
var field_suppress_depth: int = 0

var interfaces_dictionary: Dictionary = {}


func _ready() -> void:
	add_to_group("interfaces")
	_blocking_ui = [
		menu,
		party,
		summary,
		inventory,
		battle,
		storage,
		store,
		evolution_screen,
		overworld_text_box,
	]
	for c in _blocking_ui:
		c.visibility_changed.connect(_on_blocking_ui_visibility_changed)
	Global.toggle_player.connect(refresh_field_input)
	_connect_signals()
	refresh_field_input()


func _on_blocking_ui_visibility_changed() -> void:
	refresh_field_input()


func begin_field_suppress() -> void:
	field_suppress_depth += 1
	refresh_field_input()


func end_field_suppress() -> void:
	field_suppress_depth = maxi(0, field_suppress_depth - 1)
	refresh_field_input()


func refresh_field_input() -> void:
	var blocked := field_suppress_depth > 0
	if not blocked:
		for c in _blocking_ui:
			if c.visible:
				blocked = true
				break
	interfaces_dictionary.clear()
	for c in _blocking_ui:
		interfaces_dictionary[c] = c.visible
	interfaces_dictionary[player] = not blocked
	player.processing = not blocked


func _connect_signals() -> void:
	Ui.switch_ui_context.connect(_on_switch_ui_context)


func _on_switch_ui_context(new_context: Global.AccessFrom) -> void:
	ui_context = new_context
