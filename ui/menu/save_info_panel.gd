extends Panel

var minutes_since_last_save: int = 0

@onready var name_label: Label = $MarginContainer/BoxContainer/NameLabel
@onready var play_time_label: Label = $MarginContainer/BoxContainer/PlayTimeLabel
@onready var last_saved_label: Label = $MarginContainer/BoxContainer/LastSavedLabel


func _ready() -> void:
	_connect_signals()


func update_info() -> void:
	update_name_label()
	update_play_time_label()
	update_last_saved_label()


func update_name_label() -> void:
	var h := PlayerContext3D.player_info_handler
	if h and h.player_name:
		name_label.text = "NAME: %s" % h.player_name


func update_play_time_label() -> void:
	var h := PlayerContext3D.player_info_handler
	if h and h.player_name:
		play_time_label.text = "PLAY TIME: %s" % _parse_minutes(h.play_time)


func update_last_saved_label() -> void:
	if not SaverLoader.save_game_exists():
		last_saved_label.text = "LAST SAVED: NEVER"
	else:
		if minutes_since_last_save <= 1:
			last_saved_label.text = "LAST SAVED: JUST NOW"
		else:
			last_saved_label.text = "LAST SAVED: %s AGO" % [_parse_minutes(minutes_since_last_save)]


func _connect_signals() -> void:
	Ui.update_save_info.connect(_on_game_saved)
	Global.time_changed.connect(_on_time_changed)


func _on_game_saved() -> void:
	minutes_since_last_save = 0
	update_info()


func _on_time_changed() -> void:
	if SaverLoader.save_game_exists():
		minutes_since_last_save += 1
	update_info()


func _parse_minutes(num_minutes: int) -> String:
	@warning_ignore("integer_division")
	var hours = num_minutes / 60
	var minutes = num_minutes % 60

	return "%02d:%02d" % [hours, minutes]
