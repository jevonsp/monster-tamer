extends ProgressBar
var actor = null
var active: bool = false
func _ready() -> void:
	if not Global.monster_gained_experience.is_connected(_on_monster_gained_experience):
		Global.monster_gained_experience.connect(_on_monster_gained_experience)
	if not Global.monster_gained_level.is_connected(_on_monster_gained_level):
		Global.monster_gained_level.connect(_on_monster_gained_level)


func update():
	if actor != null:
		modulate = Color.WHITE
	else:
		value = 0
		modulate = Color.TRANSPARENT
	
	
func _on_monster_gained_experience(monster: Monster, amount: int) -> void:
	if monster == actor:
		if not active:
			print("not active")
			update_value(amount)
		else:
			print("active")
			tween_bar(amount)
		
func _on_monster_gained_level(monster: Monster, _amount: int) -> void:
	update_bounds(monster)
		
		
func update_value(amount: int) -> void:
	value += amount
	
	
func update_bounds(monster: Monster) -> void:
	min_value = monster.get_current_level_exp()
	value = monster.experience
	max_value = monster.get_next_level_exp()


func tween_bar(amount: int) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "value", value + amount, Global.DEFAULT_DELAY)
	await tween.finished
	Global.experience_animation_complete.emit()
