extends Node2D
const TEST_MON_MD = preload("res://monsters/test_mon/test_mon_md.tres")
const GAME_WIDTH := 1280
const GAME_HEIGHT := 720
@onready var test_map: TileMapLayer = $TestMap
@onready var player: CharacterBody2D = $Player



func _ready() -> void:
	get_window().grab_focus()
	get_window().size = Vector2i(GAME_WIDTH, GAME_HEIGHT)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	for md in [TEST_MON_MD]:
		var m = md.set_up(1)
		player.party_handler.add(m)


func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_Q):
		get_tree().quit()


func _input(event):
	if event is InputEventMouse:
		get_viewport().set_input_as_handled()
