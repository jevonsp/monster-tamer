extends Node

@onready var storage: Control = $".."


func toggle_visible() -> void:
	storage.visible = not storage.visible
	storage.processing = storage.visible
	_sync_world_input_block(storage.visible)
	if storage.visible:
		focus_default_monster()


func toggle_options_visible() -> void:
	storage.options_container.visible = not storage.options_container.visible
	if storage.options_container.visible:
		focus_default_option()
	else:
		focus_default_monster()


func set_monster_focus(button: Button) -> void:
	storage.last_selected_monster = button


func focus_default_monster() -> void:
	if storage.last_selected_monster:
		storage.last_selected_monster.grab_focus()
	else:
		storage.grid_container.get_child(0).grab_focus()


func set_option_focus(button: Button) -> void:
	storage.last_selected_option = button


func focus_default_option() -> void:
	if storage.last_selected_option == null:
		var first_button: Button = storage.options_container.get_child(0)
		first_button.grab_focus()
	else:
		storage.last_selected_option.grab_focus()


func _sync_world_input_block(should_block: bool) -> void:
	if UiFlow == null:
		return
	if should_block:
		UiFlow.register_ui_layer(storage, true)
		return
	UiFlow.unregister_ui_layer(storage)
