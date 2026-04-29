extends Node3D

@onready var grid_map: CustomGridMap = $GridMap
@onready var player: Player3D = $Player3D
@onready var interfaces: CanvasLayer = $Interfaces


func _ready() -> void:
	if grid_map:
		_assign_grid_map(self)
	get_window().grab_focus()
	get_window().size = Vector2i(Global.GAME_WIDTH, Global.GAME_HEIGHT)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	PlayerContext3D.player_info_handler.input_layout = GameOptions.control_scheme


func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_Q):
		get_tree().quit()


func _input(event):
	if event is InputEventMouse:
		get_viewport().set_input_as_handled()


func _assign_grid_map(root: Node) -> void:
	for child in root.get_children():
		if child is Character3D:
			child.grid_map = grid_map
			child.movement_helper.used_cells = grid_map.get_used_cells()
		_assign_grid_map(child)
