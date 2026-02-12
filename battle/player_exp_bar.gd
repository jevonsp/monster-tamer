extends ProgressBar
var actor

func _ready() -> void:
	Global.monster_gained_exp.connect(_on_monster_gained_exp)
	
	
func _on_monster_gained_exp(monster: Monster, amount: int) -> void:
	if actor == monster:
		await get_tree().create_timer(Global.DEFAULT_DELAY).timeout
		await tween_bar(monster, amount)
		Global.experience_animation_complete.emit()

func tween_bar(monster: Monster, amount: int):
	var experience = value
	var level = monster.level
	var base = Monster.EXPERIENCE_PER_LEVEL
	while amount >= 0:
		var next: int = level * base - experience
		if amount >= next:
			var exp_to_gain = amount - next
			amount -= next
			var tween = get_tree().create_tween()
			tween.tween_property(self, "value", exp_to_gain, Global.DEFAULT_DELAY)
			await tween.finished
			monster.gain_level()
			

func set_new_bounds(level: int) -> void:
	var min_exp = Monster.EXPERIENCE_PER_LEVEL * (level - 1)
	var max_exp = Monster.EXPERIENCE_PER_LEVEL * level
	
	min_value = min_exp
	max_value = max_exp
