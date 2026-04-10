extends Panel

const UP_ARROW = preload("uid://cx1kq2j7nown8")
const DOWN_ARROW = preload("uid://borvjxgoof7ao")

@onready var visibility_focus_handler: Node = $"../../Visibility&FocusHandler"
@onready var stab_marker: TextureRect = $MarginContainer/HBoxContainer/STABMarker
@onready var efficacy_marker: TextureRect = $MarginContainer/HBoxContainer/EfficacyMarker


func _ready() -> void:
	visibility_focus_handler.send_move_helper_panel_info.connect(_parse_information)
	_hide_marker(stab_marker)
	_hide_marker(efficacy_marker)


func toggle_visible(value: bool) -> void:
	visible = value


func _parse_information(move: Move, player_actor: Monster, enemy_actor: Monster) -> void:
	if not move:
		_hide_marker(stab_marker)
		_hide_marker(efficacy_marker)
		return

	var stab_bonus = TypeChart.get_stab_bonus(move.type, player_actor)
	if stab_bonus <= 1.0:
		_hide_marker(stab_marker)
	elif stab_bonus > 1.0:
		_show_marker(stab_marker)

	var efficacy := TypeChart.get_attacking_type_efficacy(move.type, enemy_actor)
	if efficacy < 1.0:
		_display_not_very_effective()
	elif efficacy > 1.0:
		_display_super_effective()
	else:
		_hide_marker(efficacy_marker)


func _display_super_effective() -> void:
	_show_marker(efficacy_marker)
	efficacy_marker.texture = UP_ARROW


func _display_not_very_effective() -> void:
	_show_marker(efficacy_marker)
	efficacy_marker.texture = DOWN_ARROW


func _hide_marker(marker: TextureRect) -> void:
	marker.modulate = Color.TRANSPARENT


func _show_marker(marker: TextureRect) -> void:
	marker.modulate = Color.WHITE
