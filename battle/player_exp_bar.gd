extends ProgressBar
var actor

func _ready() -> void:
	Global.monster_gained_exp.connect(_on_monster_gained_exp)
	
	
func _on_monster_gained_exp(monster: Monster, amount: int) -> void:
	if actor == monster:
		await get_tree().create_timer(Global.DEFAULT_DELAY).timeout
		value += amount
		Global.experience_animation_complete.emit()
