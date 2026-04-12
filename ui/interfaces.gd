extends CanvasLayer

const TEXT_BOX_SCENE := preload("res://ui/text_box/text_box.tscn")

@export_group("Dialogue canvas layers")
@export var dialogue_layer_field: int = 6
@export var dialogue_layer_battle: int = 6
@export var dialogue_layer_evolution: int = 6

var ui_context: Global.AccessFrom = Global.AccessFrom.NONE
var dialogue_canvas: CanvasLayer
var game_text_box: GameTextBox
var field_suppress_depth: int = 0
var interfaces_dictionary: Dictionary = { }
var _blocking_ui: Array[Control] = []

@onready var menu: Control = $Menu
@onready var options_panel: Control = $OptionsPanel
@onready var party: Control = $Party
@onready var summary: Control = $Summary
@onready var inventory: Control = $Inventory
@onready var battle: Control = $Battle
@onready var storage: Control = $Storage
@onready var store: Control = $Store
@onready var evolution_screen: Control = $EvolutionScreen
@onready var text_entry: Control = $TextEntry
@onready var world_map: Map = $WorldMap
@onready var player: Player = $"../Player"


func _ready() -> void:
	_ensure_dialogue_nodes()
	game_text_box.bind_ui_signals()
	add_to_group("interfaces")
	_blocking_ui = [
		menu,
		options_panel,
		party,
		summary,
		inventory,
		battle,
		storage,
		store,
		evolution_screen,
		game_text_box,
		text_entry,
		world_map,
	]
	for c in _blocking_ui:
		c.visibility_changed.connect(_on_blocking_ui_visibility_changed)
	Global.toggle_player.connect(refresh_field_input)
	_connect_signals()
	battle.visibility_changed.connect(_on_battle_visibility_changed)
	evolution_screen.visibility_changed.connect(_on_evolution_visibility_changed)
	call_deferred("_deferred_refresh_dialogue_presenter")
	refresh_field_input()


func refresh_dialogue_presenter() -> void:
	var mode: GameTextBox.LayoutMode = _resolve_dialogue_layout()
	match mode:
		GameTextBox.LayoutMode.FIELD:
			dialogue_canvas.layer = dialogue_layer_field
		GameTextBox.LayoutMode.BATTLE:
			dialogue_canvas.layer = dialogue_layer_battle
		GameTextBox.LayoutMode.EVOLUTION:
			dialogue_canvas.layer = dialogue_layer_evolution
	game_text_box.apply_layout_for_mode(mode)


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


func _ensure_dialogue_nodes() -> void:
	dialogue_canvas = get_node_or_null("DialogueCanvas") as CanvasLayer
	if dialogue_canvas == null:
		dialogue_canvas = CanvasLayer.new()
		dialogue_canvas.name = "DialogueCanvas"
		add_child(dialogue_canvas)

	game_text_box = dialogue_canvas.get_node_or_null("GameTextBox") as GameTextBox

	var legacy: Node = get_node_or_null("OverworldTextBox")
	if game_text_box == null and legacy != null and legacy.has_method("bind_ui_signals"):
		legacy.reparent(dialogue_canvas)
		legacy.name = "GameTextBox"
		game_text_box = legacy as GameTextBox

	if game_text_box == null:
		var inst: Node = TEXT_BOX_SCENE.instantiate()
		inst.name = "GameTextBox"
		(inst as Control).visible = false
		dialogue_canvas.add_child(inst)
		game_text_box = inst as GameTextBox


func _deferred_refresh_dialogue_presenter() -> void:
	refresh_dialogue_presenter()


func _resolve_dialogue_layout() -> GameTextBox.LayoutMode:
	if evolution_screen.visible:
		return GameTextBox.LayoutMode.EVOLUTION
	if battle.visible and ui_context == Global.AccessFrom.BATTLE:
		return GameTextBox.LayoutMode.BATTLE
	return GameTextBox.LayoutMode.FIELD


func _on_battle_visibility_changed() -> void:
	refresh_dialogue_presenter()


func _on_evolution_visibility_changed() -> void:
	refresh_dialogue_presenter()


func _on_blocking_ui_visibility_changed() -> void:
	refresh_field_input()


func _connect_signals() -> void:
	Ui.switch_ui_context.connect(_on_switch_ui_context)


func _on_switch_ui_context(new_context: Global.AccessFrom) -> void:
	ui_context = new_context
	refresh_dialogue_presenter()
