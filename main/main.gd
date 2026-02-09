extends Node2D
@onready var test_map: TileMapLayer = $TestMap
@onready var player: CharacterBody2D = $Player
const PISTOL_SHRIMP = preload("uid://cdor45ba2o0aa")

func _ready() -> void:
	get_window().grab_focus()
	var monster = PISTOL_SHRIMP.set_up(1)
	player.add(monster)
