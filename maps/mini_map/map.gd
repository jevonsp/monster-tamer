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

var current_location: Location = Location.NONE


func _ready() -> void:
	_connnect_singals()


func _connnect_singals() -> void:
	Global.location_changed.connect(_on_location_changed)


func _on_location_changed(new_location: Location) -> void:
	if new_location == current_location:
		return
	current_location = new_location
