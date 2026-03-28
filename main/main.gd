extends Node2D

const GAME_WIDTH := 1280
const GAME_HEIGHT := 720

@onready var test_map: TileMapLayer = $TestMap
@onready var player: CharacterBody2D = $Player


func _ready() -> void:
	print(Time.get_time_dict_from_system())

	get_window().grab_focus()
	get_window().size = Vector2i(GAME_WIDTH, GAME_HEIGHT)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	set_references()


func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_Q):
		get_tree().quit()


func _input(event):
	if event is InputEventMouse:
		get_viewport().set_input_as_handled()


func set_references() -> void:
	player.current_map = test_map
