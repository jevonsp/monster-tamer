extends Control

@export var time_label: Label
@export var period_label: Label


func _ready() -> void:
	_connect_signals()
	if not visible:
		_toggle_visible()

	_update_time()


func _connect_signals() -> void:
	Global.time_changed.connect(_update_time)
	Global.period_of_day_changed.connect(_update_time)


func _toggle_visible() -> void:
	visible = not visible


func _update_time() -> void:
	var time_of_day_str = "%s:%s" % [TimeKeeper.hour_minute.x, TimeKeeper.hour_minute.y]
	time_label.text = time_of_day_str
	_update_period()


func _update_period() -> void:
	var period_of_day_str: String = TimeKeeper.Period.keys()[TimeKeeper.period].to_upper()
	period_label.text = period_of_day_str
