extends ProgressBar
var actor

func _ready() -> void:
	Global.send_hitpoints_change.connect(_on_send_hitpoints_change)


func _on_send_hitpoints_change(target: Monster, new_hp: int) -> void:
	if target != actor:
		return
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "value", new_hp, Global.DEFAULT_DELAY)
	
	await tween.finished
	
	Global.hitpoints_animation_complete.emit()
