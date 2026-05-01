class_name BattleScene3D
extends Node3D

enum VisibleButtons { OPTIONS, MOVES }

var battle_chassis: BattleChassis
var processing: bool = false
var button_state: VisibleButtons = VisibleButtons.OPTIONS
var last_focused_move_button: Button = null
var last_focused_option_button: Button = null
var _player_actor_0: Monster
var _enemy_actor_0: Monster
var _is_registered_with_ui_flow: bool = false

@onready var move_0_label: Label = $CanvasLayer/Content/MoveButtons/Move0/Label
@onready var move_1_label: Label = $CanvasLayer/Content/MoveButtons/Move1/Label
@onready var move_2_label: Label = $CanvasLayer/Content/MoveButtons/Move2/Label
@onready var move_3_label: Label = $CanvasLayer/Content/MoveButtons/Move3/Label
@onready var stab_marker: TextureRect = $CanvasLayer/Content/MoveInfoHelperPanel/MarginContainer/HBoxContainer/STABMarker
@onready var efficacy_marker: TextureRect = $CanvasLayer/Content/MoveInfoHelperPanel/MarginContainer/HBoxContainer/EfficacyMarker
@onready var move_description_panel: Button = $CanvasLayer/Content/MoveDescriptionPanel
@onready var player_level_label: Label = $CanvasLayer/Content/PlayerPanel/VBoxContainer/PlayerLevelLabel
@onready var player_name_label: Label = $CanvasLayer/Content/PlayerPanel/VBoxContainer/PlayerNameLabel
@onready var player_texture_rect: TextureRect = $CanvasLayer/Content/Animations/PlayerTextureRect
@onready var player_hp_bar: TextureProgressBar = $CanvasLayer/Content/PlayerHPBar
@onready var player_exp_bar: TextureProgressBar = $CanvasLayer/Content/PlayerEXPBar
@onready var enemy_name_label: Label = $CanvasLayer/Content/EnemyPanel/VBoxContainer/EnemyNameLabel
@onready var enemy_texture_rect: TextureRect = $CanvasLayer/Content/Animations/EnemyTextureRect
@onready var enemy_hp_bar: TextureProgressBar = $CanvasLayer/Content/EnemyHPBar
@onready var move_0: Button = $CanvasLayer/Content/MoveButtons/Move0
@onready var move_1: Button = $CanvasLayer/Content/MoveButtons/Move1
@onready var move_2: Button = $CanvasLayer/Content/MoveButtons/Move2
@onready var move_3: Button = $CanvasLayer/Content/MoveButtons/Move3
@onready var player_0_slot: Array = [
	move_0,
	move_1,
	move_2,
	move_3,
	stab_marker,
	efficacy_marker,
	move_description_panel,
	player_level_label,
	player_name_label,
	player_texture_rect,
	player_hp_bar,
	player_exp_bar,
]
@onready var enemy_0_slot: Array = [
	enemy_name_label,
	enemy_texture_rect,
	enemy_hp_bar,
]
@onready var move_buttons: GridContainer = $CanvasLayer/Content/MoveButtons
@onready var option_buttons: GridContainer = $CanvasLayer/Content/OptionButtons
@onready var fight: Button = $CanvasLayer/Content/OptionButtons/Fight
@onready var party: Button = $CanvasLayer/Content/OptionButtons/Party
@onready var item: Button = $CanvasLayer/Content/OptionButtons/Item
@onready var run: Button = $CanvasLayer/Content/OptionButtons/Run
@onready var animation_player: MoveAnimator = $CanvasLayer/Content/Animations/AnimationPlayer
@onready var fx_player: AnimationPlayer = $CanvasLayer/Content/Animations/FxPlayer
@onready var canvas_layer: CanvasLayer = $CanvasLayer


func _ready() -> void:
	Battle.set_battle_scene(self)
	_connect_signals()
	_bind_buttons()
	_focus_default()
	canvas_layer.visible = visible


func _exit_tree() -> void:
	if Battle != null:
		Battle.set_battle_scene(null)


func _unhandled_input(event: InputEvent) -> void:
	if battle_chassis.is_processing_turn():
		return

	match button_state:
		VisibleButtons.OPTIONS:
			if event.is_action_pressed("no"):
				run.grab_focus()
		VisibleButtons.MOVES:
			if event.is_action_pressed("no"):
				_change_button_state(VisibleButtons.OPTIONS)


func show_text(lines: Array[String], auto_complete: bool = false) -> void:
	Ui.send_text_box.emit(null, lines, auto_complete, false, false)
	await Ui.text_box_complete


func play_move_animation(choice: Choice) -> void:
	if choice.type == Choice.Type.MOVE:
		var anim = choice.action_or_list.get_animation_name()
		await animation_player._play_animation(anim)


func play_fx(fx_id: StringName, payload: Dictionary = { }) -> void:
	match fx_id:
		&"hit":
			@warning_ignore("redundant_await")
			await fx_player.play_hit(payload.get("target"), _player_actor_0, _enemy_actor_0)
		&"throw":
			@warning_ignore("redundant_await")
			await fx_player.play_throw_item(payload.get("item"))
		&"faint":
			@warning_ignore("redundant_await")
			await fx_player.play_faint(payload.get("target"), _player_actor_0, _enemy_actor_0)


func tween_hp(target: Monster, _from_hp: int, to_hp: int) -> void:
	var bar: TextureProgressBar = null
	if target == _player_actor_0:
		bar = player_hp_bar
	elif target == _enemy_actor_0:
		bar = enemy_hp_bar
	if bar == null:
		Battle.hitpoints_animation_complete.emit()
		return
	var tween := get_tree().create_tween()
	tween.tween_property(bar, "value", to_hp * 100, Global.DEFAULT_DELAY)
	await tween.finished
	Battle.hitpoints_animation_complete.emit()


func set_battle_chassis(value: BattleChassis) -> void:
	if battle_chassis != null and battle_chassis.actors_changed.is_connected(_bind_actors):
		battle_chassis.actors_changed.disconnect(_bind_actors)
	battle_chassis = value
	if battle_chassis != null and not battle_chassis.actors_changed.is_connected(_bind_actors):
		battle_chassis.actors_changed.connect(_bind_actors)
	_bind_actors(
		battle_chassis.player_actors if battle_chassis != null else { },
		battle_chassis.enemy_actors if battle_chassis != null else { },
	)


func _bind_buttons() -> void:
	for button: Button in [
		move_0,
		move_1,
		move_2,
		move_3,
	]:
		button.focus_entered.connect(_on_move_focus_entered.bind(button))
		button.pressed.connect(_on_move_pressed.bind(button))
	for button: Button in [
		fight,
		party,
		item,
		run,
	]:
		button.focus_entered.connect(_on_option_focus_entered.bind(button))
		button.pressed.connect(_on_option_pressed.bind(button))
	fight.pressed.connect(_change_button_state.bind(VisibleButtons.MOVES))


func _connect_signals() -> void:
	if battle_chassis != null and not battle_chassis.actors_changed.is_connected(_bind_actors):
		battle_chassis.actors_changed.connect(_bind_actors)

	if not Battle.battle_started.is_connected(_toggle_visible):
		Battle.battle_started.connect(_toggle_visible)

	if not Battle.battle_ended.is_connected(_toggle_visible):
		Battle.battle_ended.connect(_toggle_visible)


func _bind_actors(
		p_actors: Dictionary[int, Monster],
		e_actors: Dictionary[int, Monster],
) -> void:
	_player_actor_0 = p_actors.get(0, null)
	_enemy_actor_0 = e_actors.get(0, null)
	for node: Node in player_0_slot:
		if node.has_method(&"set_actor"):
			node.set_actor(_player_actor_0)
	for node: Node in enemy_0_slot:
		if node.has_method(&"set_actor"):
			node.set_actor(_enemy_actor_0)


func _toggle_visible(_trainer3d: Trainer3D = null) -> void:
	visible = not visible
	canvas_layer.visible = visible
	processing = visible
	_sync_world_input_block(visible)
	if visible:
		_focus_default()
		Ui.switch_ui_context.emit(Global.AccessFrom.MENU)
	else:
		last_focused_move_button = null
		last_focused_option_button = null


func _sync_world_input_block(should_block: bool) -> void:
	if UiFlow == null:
		return
	if should_block:
		if _is_registered_with_ui_flow:
			return
		UiFlow.register_ui_layer(self, true)
		_is_registered_with_ui_flow = true
		return
	if not _is_registered_with_ui_flow:
		return
	UiFlow.unregister_ui_layer(self)
	_is_registered_with_ui_flow = false


func _focus_default() -> void:
	match button_state:
		VisibleButtons.OPTIONS:
			if last_focused_option_button:
				last_focused_option_button.grab_focus()
			else:
				fight.grab_focus()
		VisibleButtons.MOVES:
			if last_focused_move_button:
				last_focused_move_button.grab_focus()
			else:
				move_0.grab_focus()


func _change_button_state(state: VisibleButtons) -> bool:
	if state == button_state:
		return false
	button_state = state
	match state:
		VisibleButtons.OPTIONS:
			move_buttons.visible = false
			option_buttons.visible = true
		VisibleButtons.MOVES:
			move_buttons.visible = true
			option_buttons.visible = false

	_focus_default()

	return true


func _on_move_focus_entered(button: Button) -> void:
	last_focused_move_button = button
	var actor = Battle.resolve_player_actor()
	if not actor:
		return
	var idx = int(button.name)
	if idx > actor.moves.size():
		return
	var move = actor.moves.get(idx)
	if move:
		button.display()
		stab_marker.display(move)
		move_description_panel.display(move)


func _on_option_focus_entered(button: Button) -> void:
	last_focused_option_button = button


func _on_option_pressed(button: Button) -> void:
	print(button.name)


func _on_move_pressed(button: Button) -> void:
	print(int(button.name))
	var actor = Battle.resolve_player_actor()
	if not actor:
		return
	var idx = int(button.name)
	if idx > actor.moves.size():
		return
	var move = actor.moves.get(idx)
	if move:
		@warning_ignore("redundant_await")
		await Battle.enqueue_move_choice(move)
