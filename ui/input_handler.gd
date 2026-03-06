extends Node
@onready var storage: Control = $".."
#region Helper Nodes
@onready var visiblity_focus_handler: Node = $"../Visiblity&FocusHandler"
@onready var update_handler: Node = $"../UpdateHandler"
#endregion

func _input(event: InputEvent) -> void:
	if not storage.processing:
		return
	if event.is_action_pressed("no") and storage.options_container.visible:
		visiblity_focus_handler._toggle_options_visible()
	if event.is_action_pressed("left") and storage.last_selected_monster.is_in_group("left_side"):
		move_page(Vector2.LEFT)
	if event.is_action_pressed("right") and storage.last_selected_monster.is_in_group("right_side"):
		move_page(Vector2.RIGHT)


func _on_monster_pressed(b: Button) -> void:
	match storage.state:
		storage.State.DEFAULT:
			print("DEFAULT")
			visiblity_focus_handler._toggle_options_visible()
		storage.State.MOVING:
			print("MOVING")

func _on_option_pressed(b: Button) -> void:
	match b.name:
		"Move":
			print("Move")
		"Withdraw":
			print("Withdraw")
		"Deposit":
			print("Deposit")
		"Release":
			print("Release")


func move_page(dir: Vector2) -> void:
	match dir:
		Vector2.LEFT:
			storage.page_index = posmod(storage.page_index - 1, 10)
		Vector2.RIGHT:
			storage.page_index = (storage.page_index + 1) % 10
	update_handler.display_monsters()
