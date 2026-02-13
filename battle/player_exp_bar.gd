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
	var base = Monster.EXPERIENCE_PER_LEVEL
	var remaining_exp = amount
	
	while remaining_exp > 0:
		var current_exp = monster.experience
		var exp_needed = base * monster.level - current_exp
		var exp_to_gain = min(remaining_exp, exp_needed)
		
		var tween = get_tree().create_tween()
		tween.tween_property(self, "value", current_exp + exp_to_gain, Global.DEFAULT_DELAY)
		await tween.finished
		
		monster.experience += exp_to_gain
		remaining_exp -= exp_to_gain
		
		if monster.experience >= base * monster.level:
			monster.gain_level()
			set_new_bounds(monster.level)
			value = monster.experience
		
	set_new_bounds(monster.level)
			

func set_new_bounds(level: int) -> void:
	var min_exp = Monster.EXPERIENCE_PER_LEVEL * (level - 1)
	var max_exp = Monster.EXPERIENCE_PER_LEVEL * level
	
	min_value = min_exp
	max_value = max_exp
