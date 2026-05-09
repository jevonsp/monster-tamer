class_name GameOptions
extends Resource

const CONTROL_SCHEME_XBOX_SONY := 0
const CONTROL_SCHEME_NINTENDO := 1
const CONTROL_SCHEME_COUNT := 2
const GAME_VARIANT_NORMAL := 0
const GAME_VARIANT_NUZLOCKE := 1
const GAME_VARIANT_COUNT := 2

@export var control_scheme: int = CONTROL_SCHEME_XBOX_SONY
@export var game_variant: int = GAME_VARIANT_NUZLOCKE
@export var can_change_variant: bool = true
@export var is_forgetful_saver: bool = false


func is_nuzlocke() -> bool:
	return game_variant == GAME_VARIANT_NUZLOCKE


func reset_defaults() -> void:
	control_scheme = CONTROL_SCHEME_XBOX_SONY
	game_variant = GAME_VARIANT_NUZLOCKE
	can_change_variant = true
	is_forgetful_saver = false


func hydrate_legacy(raw: Variant, legacy_input_layout: Variant = null) -> void:
	if raw is Resource:
		var data = raw
		control_scheme = _to_control_scheme(data.control_scheme)
		game_variant = _to_game_variant(data.game_variant)
		can_change_variant = data.can_change_variant
		is_forgetful_saver = data.is_forgetful_saver
		return
	if typeof(raw) == TYPE_DICTIONARY:
		var d: Dictionary = raw
		control_scheme = _to_control_scheme(d.get("control_scheme", legacy_input_layout))
		game_variant = _to_game_variant(d.get("game_variant", game_variant))
		can_change_variant = d.get("can_change_variant", can_change_variant) if typeof(d.get("can_change_variant", can_change_variant)) == TYPE_BOOL else can_change_variant
		is_forgetful_saver = d.get("is_forgetful_saver", is_forgetful_saver) if typeof(d.get("is_forgetful_saver", is_forgetful_saver)) == TYPE_BOOL else is_forgetful_saver
		return
	if legacy_input_layout != null:
		control_scheme = _to_control_scheme(legacy_input_layout)


func _to_control_scheme(value: Variant) -> int:
	if typeof(value) != TYPE_INT:
		return CONTROL_SCHEME_XBOX_SONY
	return clampi(int(value), 0, CONTROL_SCHEME_COUNT - 1)


func _to_game_variant(value: Variant) -> int:
	if typeof(value) != TYPE_INT:
		return GAME_VARIANT_NUZLOCKE
	return clampi(int(value), 0, GAME_VARIANT_COUNT - 1)
