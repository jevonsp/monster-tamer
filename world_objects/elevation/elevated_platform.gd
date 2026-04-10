extends Node2D

@export var height_level: int = 1

@onready var left_rail: StaticBody2D = $LeftRail
@onready var right_rail: StaticBody2D = $RightRail


func _ready() -> void:
	Global.player_elevation_changed.connect(_on_player_height_level_changed)


func _on_player_height_level_changed(player_height_level: int) -> void:
	if player_height_level == height_level:
		process_mode = Node.PROCESS_MODE_ALWAYS
	else:
		process_mode = Node.PROCESS_MODE_DISABLED
