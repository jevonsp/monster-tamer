extends TextureProgressBar

const SMOOTH_SCALE: int = 100

var actor: Monster = null


func _ready() -> void:
	Battle.send_hitpoints_change.connect(_on_send_hitpoints_change)


func update() -> void:
	if actor:
		max_value = actor.max_hitpoints * SMOOTH_SCALE
		value = actor.current_hitpoints * SMOOTH_SCALE
		modulate = Color.WHITE
	else:
		value = 0
		modulate = Color.TRANSPARENT


func _on_send_hitpoints_change(target: Monster, _from_hp: int, to_hp: int) -> void:
	if target != actor:
		return

	var tween = get_tree().create_tween()
	tween.tween_property(self, "value", to_hp * SMOOTH_SCALE, Global.DEFAULT_DELAY)

	await tween.finished

	Battle.hitpoints_animation_complete.emit()
