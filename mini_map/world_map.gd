class_name Map
extends Control

enum Location {
	NONE,
	DEMO_TOWN,
	ROUTE_ONE,
	DEMO_FOREST,
	ELEVATED_PATH,
	DEMO_CAVE,
	DEMO_CITY,
}

var processing: bool = false
var location_list: Array[Location] = []
var map_rect_list: Array[MapRect] = []

@onready var cursor: CharacterBody2D = $Cursor
@onready var location_label: Label = $Panel/MarginContainer/LocationLabel


func _ready() -> void:
	visibility_changed.connect(_sync_cursor_input_enabled)
	_connect_signals()
	_sync_marker_from_player()
	call_deferred("_sync_cursor_input_enabled")


func _exit_tree() -> void:
	if UiFlow != null:
		UiFlow.unregister_ui_layer(self)


func _input(event: InputEvent) -> void:
	if not processing:
		return
	if event.is_action_pressed("no"):
		_toggle_visible()
		Ui.request_open_menu.emit()
	elif event.is_action_pressed("menu"):
		_toggle_visible()


func _connect_signals() -> void:
	for child in get_children():
		if child is MapRect:
			map_rect_list.append(child)
			child.cursor = cursor
			child.cursor_entered.connect(_on_cursor_location_entered)
			child.cursor_exited.connect(_on_cursor_location_exited)
	Ui.request_open_map.connect(_toggle_visible)


func _toggle_visible() -> void:
	visible = not visible
	processing = visible
	if UiFlow != null:
		if visible:
			UiFlow.register_ui_layer(self, true)
		else:
			UiFlow.unregister_ui_layer(self)
	if visible:
		for map_rect in map_rect_list:
			if map_rect.bobble_tween:
				if map_rect.cursor == null:
					map_rect.cursor = cursor
				map_rect._position_cursor()
				return


func _sync_cursor_input_enabled() -> void:
	cursor.processing = visible


func _sync_marker_from_player() -> void:
	if PlayerContext3D.player == null:
		return
	Global.location_changed.emit(PlayerContext3D.travel_handler.current_location)


func _on_cursor_location_entered(cursor_location: Map.Location) -> void:
	location_list.append(cursor_location)
	location_label.text = "LOCATION: %s" % [Map.Location.keys()[location_list.back()].to_lower().capitalize()]
	if location_list.size() >= 1:
		cursor.start_animation()
	else:
		cursor.stop_animation()


func _on_cursor_location_exited(cursor_location) -> void:
	location_list.erase(cursor_location)
	if location_list.size() >= 1:
		location_label.text = "LOCATION: %s" % [Map.Location.keys()[location_list.back()].to_lower().capitalize()]
		cursor.start_animation()
	else:
		location_label.text = "LOCATION: --"
		cursor.stop_animation()
