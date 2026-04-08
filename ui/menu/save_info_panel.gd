extends Panel

var minutes_since_last_save: int = 0

@onready var name_label: Label = $MarginContainer/BoxContainer/NameLabel
@onready var play_time_label: Label = $MarginContainer/BoxContainer/PlayTimeLabel
@onready var last_saved_label: Label = $MarginContainer/BoxContainer/LastSavedLabel


func display_info() -> void:
	display_name_label()
	display_play_time_label()
	display_last_saved_label()


func display_name_label() -> void:
	pass


func display_play_time_label() -> void:
	pass


func display_last_saved_label() -> void:
	if not SaverLoader.save_game_exists():
		last_saved_label.text = "LAST SAVED: NEVER"
	else:
		last_saved_label.text = "LAST SAVED: %s" % [_parse_minutes()]


func _connect_signals() -> void:
	Ui.update_save_info.connect(_on_game_saved)
	Global.time_changed.connect(_on_time_changed)


func _on_game_saved() -> void:
	minutes_since_last_save = 0


func _on_time_changed() -> void:
	if SaverLoader.save_game_exists():
		minutes_since_last_save += 1


func _parse_minutes() -> String:
	@warning_ignore("integer_division")
	var hours = minutes_since_last_save / 60
	var minutes = minutes_since_last_save % 60

	return "%s:%s" % [hours, minutes]
