extends ProgressBar
var actor = null
var is_animating: bool = false
func _ready() -> void:
	if not Global.monster_gained_exp.is_connected(_on_monster_gained_exp):
		Global.monster_gained_exp.connect(_on_monster_gained_exp)
	
	
func _on_monster_gained_exp(monster: Monster, amount: int) -> void:
	print("signal received by: ", get_path(), " is_animating=", is_animating)
	if actor == monster:
		if not visible:
			return
		await get_tree().create_timer(Global.DEFAULT_DELAY).timeout
		await tween_bar(monster, amount)
		Global.experience_animation_complete.emit()



func update_values(lvl: int, val) -> void:
	var min_exp: int = Monster.EXPERIENCE_PER_LEVEL * (lvl - 1)
	var max_exp: int = Monster.EXPERIENCE_PER_LEVEL * lvl
	min_value = min_exp
	value = val
	max_value = max_exp


func tween_bar(monster: Monster, amount: int):
	if is_animating: 
		return
	is_animating = true
	var base = Monster.EXPERIENCE_PER_LEVEL
	var remaining_exp = amount
	print("tween_bar start: amount=%d, monster.exp=%d, monster.level=%d" % [amount, monster.experience, monster.level])
	
	while remaining_exp > 0:
		var current_exp = monster.experience
		var exp_needed = base * monster.level - current_exp
		var exp_to_gain = min(remaining_exp, exp_needed)
		
		print("loop: remaining=%d, current_exp=%d, exp_needed=%d, exp_to_gain=%d, bar.value=%f" % [remaining_exp, current_exp, exp_needed, exp_to_gain, value])
		
		var tween = get_tree().create_tween()
		tween.tween_property(self, "value", current_exp + exp_to_gain, Global.DEFAULT_DELAY)
		await tween.finished
		print("tween finished: bar.value=%f" % value)
		
		monster.experience += exp_to_gain
		remaining_exp -= exp_to_gain
		print("after update: monster.exp=%d, remaining=%d" % [monster.experience, remaining_exp])
		
		if monster.experience >= base * monster.level:
			print("leveling up from %d" % monster.level)
			await monster.gain_level()
			set_new_bounds(monster.level)
			value = monster.experience  # this sets value AFTER set_new_bounds resets it — correct
			print("after level up: level=%d, bar.value=%f, min=%f, max=%f" % [monster.level, value, min_value, max_value])
			is_animating = false
			return
		
	set_new_bounds(monster.level)
	print("tween_bar done: bar.value=%f, min=%f, max=%f" % [value, min_value, max_value])
	is_animating = false
			

func set_new_bounds(level: int) -> void:
	var min_exp = Monster.EXPERIENCE_PER_LEVEL * (level - 1)
	var max_exp = Monster.EXPERIENCE_PER_LEVEL * level
	min_value = min_exp
	value = min_value
	max_value = max_exp

func update():
	if actor != null:
		set_new_bounds(actor.level)
		modulate = Color.WHITE
	else:
		value = 0
		modulate = Color.TRANSPARENT
