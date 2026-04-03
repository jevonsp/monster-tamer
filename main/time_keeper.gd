class_name TimeKeeper
extends Node

enum Period { NIGHT, DAWN, DAY, DUSK }

static var period: Period = Period.DAY:
	set(value):
		period = value
		Global.period_of_day_changed.emit()
	get:
		return interpret_current_time()
static var hour_minute: Vector2i = Vector2i.ZERO:
	set(value):
		hour_minute = value
		Global.time_changed.emit()


static func interpret_current_time() -> Period:
	match hour_minute.x:
		22, 23, 0, 1, 2, 3:
			return Period.NIGHT
		4, 5, 6, 7, 8, 9:
			return Period.DAWN
		10, 11, 12, 13, 14, 15:
			return Period.DAY
		16, 17, 18, 19, 20, 21:
			return Period.DUSK
		_:
			return Period.DAY


func _ready() -> void:
	_set_time()
	_start_minute_sync()


func _set_time():
	hour_minute.x = Time.get_time_dict_from_system().hour
	hour_minute.y = Time.get_time_dict_from_system().minute
	period = interpret_current_time()
	Global.time_changed.emit()


func _start_minute_sync() -> void:
	var second: int = Time.get_time_dict_from_system().second
	await get_tree().create_timer(60 - second).timeout
	_set_time()

	var timer := Timer.new()
	add_child(timer)
	timer.wait_time = 60.0
	timer.timeout.connect(_set_time)
	timer.start()
