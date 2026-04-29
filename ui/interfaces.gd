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
var _last_blocked: bool = false

@onready var evolution_screen: Control = $EvolutionScreen


func _ready() -> void:
	_ensure_dialogue_nodes()
	game_text_box.bind_ui_signals()
	add_to_group("interfaces")
	Global.toggle_player.connect(refresh_field_input)
	_connect_signals()
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
	if not blocked and UiFlow != null and UiFlow.is_world_input_blocked():
		blocked = true
	var player_3d = PlayerContext3D.player
	if player_3d:
		var allow_player_input: bool = not blocked and not player_3d.command_active
		player_3d.processing = allow_player_input
		if _last_blocked and not blocked:
			player_3d.clear_inputs()
		_last_blocked = blocked


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
	return GameTextBox.LayoutMode.FIELD


func _on_battle_visibility_changed() -> void:
	refresh_dialogue_presenter()


func _on_evolution_visibility_changed() -> void:
	refresh_dialogue_presenter()


func _connect_signals() -> void:
	Ui.switch_ui_context.connect(_on_switch_ui_context)
	if UiFlow != null and not UiFlow.world_input_block_state_changed.is_connected(_on_world_input_block_state_changed):
		UiFlow.world_input_block_state_changed.connect(_on_world_input_block_state_changed)


func _on_switch_ui_context(new_context: Global.AccessFrom) -> void:
	ui_context = new_context
	refresh_dialogue_presenter()


func _on_world_input_block_state_changed(_is_blocked: bool) -> void:
	refresh_field_input()
