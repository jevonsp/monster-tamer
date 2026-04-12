class_name Map
extends Node2D

enum Location {
	NONE,
	_TOWN,
	ROUTE_ONE,
	_LAKE,
	_FOREST,
	ROUTE_TWO,
	_PATH,
	_CITY,
}

var location_list: Array[Location] = []

@onready var cursor: CharacterBody2D = $Cursor
@onready var location_label: Label = $CanvasLayer/Panel/MarginContainer/LocationLabel


func _ready() -> void:
	_connect_signals()
	_sync_marker_from_player()


func _connect_signals() -> void:
	for child in get_children():
		if child is MapRect:
			child.cursor = cursor
			child.cursor_entered.connect(_on_cursor_location_entered)
			child.cursor_exited.connect(_on_cursor_location_exited)


func _sync_marker_from_player() -> void:
	if Player.travel == null:
		return
	Global.location_changed.emit(Player.travel.current_location)


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
