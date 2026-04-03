extends CanvasLayer

var ui_context: Global.AccessFrom = Global.AccessFrom.NONE

func _ready() -> void:
	_connect_signals()
	
	
func _connect_signals() -> void:
	Ui.switch_ui_context.connect(_on_switch_ui_context)


func _on_switch_ui_context(new_context: Global.AccessFrom) -> void:
	ui_context = new_context
