extends CanvasLayer

var ui_context: Global.AccessFrom = Global.AccessFrom.NONE

func _ready() -> void:
	_connect_signals()
	
	
func _connect_signals() -> void:
	Global.switch_ui_context.connect(_on_switch_ui_context)


func _on_switch_ui_context(new_context: Global.AccessFrom) -> void:
	ui_context = new_context
	var access_from_name := func(value: int) -> String: return Global.AccessFrom.find_key(value)
	print("UI Context: ", access_from_name.call(ui_context))
