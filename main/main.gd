extends Node2D
@onready var test_map: TileMapLayer = $TestMap
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	get_window().grab_focus()
