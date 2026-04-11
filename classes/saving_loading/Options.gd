extends Node

enum ControlScheme { XBOX_SONY, NINTENDO }
enum GameVariant { NORMAL, NUZLOCKE }

var control_scheme: ControlScheme = ControlScheme.XBOX_SONY
var game_variant: GameVariant = GameVariant.NORMAL
var is_forgetful_saver: bool = false


func _ready() -> void:
	SaverLoader.load_config()
