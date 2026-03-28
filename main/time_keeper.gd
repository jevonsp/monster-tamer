class_name TimeKeeper
extends Node

enum TimeOfDay { NIGHT, DAWN, DAY, DUSK }

static var current_time: TimeOfDay = TimeOfDay.DAY


static func interpret_current_time() -> TimeOfDay:
	var hour: int = Time.get_time_dict_from_system().hour
	match hour:
		22, 23, 0, 1, 2, 3:
			return TimeOfDay.NIGHT
		4, 5, 6, 7, 8, 9:
			return TimeOfDay.DAWN
		10, 11, 12, 13, 14, 15:
			return TimeOfDay.DAY
		16, 17, 18, 19, 20, 21:
			return TimeOfDay.DUSK
		_:
			return TimeOfDay.DAY


func _ready() -> void:
	_set_time()


func _set_time():
	current_time = interpret_current_time()
