extends Node2D
@onready var test_map: TileMapLayer = $TestMap
@onready var player: CharacterBody2D = $Player
const TESTMON_DATA = preload("uid://dgl3ljdmiqueh")

func _ready() -> void:
	get_window().grab_focus()
	var monster = TESTMON_DATA.set_up(1)
	player.add(monster)
