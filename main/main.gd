extends Node2D
@onready var test_map: TileMapLayer = $TestMap
@onready var player: CharacterBody2D = $Player
const PISTOL_SHRIMP = preload("uid://cdor45ba2o0aa")

func _ready() -> void:
	get_window().grab_focus()
	get_window().size = Vector2i(1280, 720)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var monster = PISTOL_SHRIMP.set_up(1)
	player.add(monster)


func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_Q):
		get_tree().quit()


func _input(event):
	if event is InputEventMouse:
		get_viewport().set_input_as_handled()
