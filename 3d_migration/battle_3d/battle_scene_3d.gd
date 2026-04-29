class_name BattleScene3D
extends Node3D

var battle_chassis: BattleChassis
var processing: bool = false
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
@onready var player_level_label: Label = $CanvasLayer/Content/PlayerPanel/VBoxContainer/PlayerLevelLabel
@onready var player_name_label: Label = $CanvasLayer/Content/PlayerPanel/VBoxContainer/PlayerNameLabel
@onready var player_texture_rect: TextureRect = $CanvasLayer/Content/PlayerTextureRect
@onready var player_hp_bar: TextureProgressBar = $CanvasLayer/Content/PlayerHPBar
@onready var player_exp_bar: TextureProgressBar = $CanvasLayer/Content/PlayerEXPBar
@onready var enemy_name_label: Label = $CanvasLayer/Content/EnemyPanel/VBoxContainer/EnemyNameLabel
@onready var enemy_texture_rect: TextureRect = $CanvasLayer/Content/EnemyTextureRect
@onready var enemy_hp_bar: TextureProgressBar = $CanvasLayer/Content/EnemyHPBar
@onready var player_0_slot: Array = [
	move_0_label,
	move_1_label,
	move_2_label,
	move_3_label,
	stab_marker,
	efficacy_marker,
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


func _ready() -> void:
	Battle.set_battle_scene(self)
	_connect_signals()


func _exit_tree() -> void:
	if Battle != null:
		Battle.set_battle_scene(null)


func show_text(_lines: Array[String], _auto_complete: bool = false) -> void:
	pass


func play_move_animation(_choice: Choice) -> void:
	pass


func play_fx(_fx_id: StringName, _payload: Dictionary = { }) -> void:
	pass


func tween_hp(_target: Monster, _from_hp: int, _to_hp: int) -> void:
	var bar: TextureProgressBar = null
	if _target == _player_actor_0:
		bar = player_hp_bar
	elif _target == _enemy_actor_0:
		bar = enemy_hp_bar
	if bar == null:
		Battle.hitpoints_animation_complete.emit()
		return
	var tween := get_tree().create_tween()
	tween.tween_property(bar, "value", _to_hp * 100, Global.DEFAULT_DELAY)
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


func _connect_signals() -> void:
	if battle_chassis != null and not battle_chassis.actors_changed.is_connected(_bind_actors):
		battle_chassis.actors_changed.connect(_bind_actors)

	if not Battle.battle_started.is_connected(_toggle_visible):
		Battle.battle_started.connect(_toggle_visible)


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


func _toggle_visible() -> void:
	visible = not visible
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
	pass
