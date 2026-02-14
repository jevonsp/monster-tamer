extends ProgressBar
var actor = null

func _ready() -> void:
	Global.send_hitpoints_change.connect(_on_send_hitpoints_change)


func _on_send_hitpoints_change(target: Monster, new_hp: int) -> void:
	if target != actor:
		return
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "value", new_hp, Global.DEFAULT_DELAY)
	
	await tween.finished
	
	Global.hitpoints_animation_complete.emit()

func update():
	if actor != null:
		max_value = actor.max_hitpoints
		value = actor.current_hitpoints
		modulate = Color.WHITE
	else:
		value = 0
		modulate = Color.TRANSPARENT
