extends Control
var processing: bool = false
func _ready() -> void:
	_connect_signals()
	
	
func _unhandled_input(event: InputEvent) -> void:
	pass
	
	
func _connect_signals() -> void:
	Global.request_open_storage.connect(_on_request_open_storage)
	
	
func _on_request_open_storage() -> void:
	_toggle_visible()
	
	
func _toggle_visible() -> void:
	visible = not visible
	processing = not processing
