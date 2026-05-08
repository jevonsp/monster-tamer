extends Node

enum ControlScheme { XBOX_SONY, NINTENDO }
enum GameVariant { NORMAL, NUZLOCKE }

var control_scheme: ControlScheme = ControlScheme.XBOX_SONY
var game_variant: GameVariant = GameVariant.NUZLOCKE
var can_change_variant: bool = true
var is_forgetful_saver: bool = false


func _ready() -> void:
	SaverLoader.load_config()


func is_nuzlocke() -> bool:
	return game_variant == GameVariant.NUZLOCKE


func _reset() -> void:
	control_scheme = ControlScheme.XBOX_SONY
	game_variant = GameVariant.NUZLOCKE
	can_change_variant = true
