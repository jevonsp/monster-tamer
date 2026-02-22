class_name Monster
extends Resource
## An instance of a monster
static var EXPERIENCE_PER_LEVEL = 50
@export var monster_data: MonsterData
@export var name: String = ""

@export var level: int = 1
@export var experience: int = 0

@export var max_hitpoints: int = 10
@export var current_hitpoints: int
@export var attack: int = 1
@export var defense: int = 1
@export var speed: int = 1

@export var moves: Array = []

@export var is_fainted: bool = false
@export var was_in_battle: bool = false

func set_monster_data(md: MonsterData) -> void:
	monster_data = md
	name = monster_data.species


func set_level(l: int) -> void:
	"""Always use this to set level. Keeps EXP correct"""
	level = l
	experience = EXPERIENCE_PER_LEVEL * (level - 1)


func set_monster_moves() -> void:
	var move_level = monster_data.move_level
	var move_gained = monster_data.move_gained
	var moves_to_gain: Array[Move] = [null, null, null, null]
	for i in range(len(move_gained)):
		if move_level[i] <= level:
			moves_to_gain.pop_back()
			moves_to_gain.push_front(move_gained[i])
	moves = moves_to_gain


func set_stats() -> void:
	current_hitpoints = max_hitpoints


func take_damage(amount: int) -> void:
	current_hitpoints = max(0, current_hitpoints - amount)
	Global.send_hitpoints_change.emit(self, current_hitpoints)
	if current_hitpoints <= 0:
		await Global.hitpoints_animation_complete
		faint()


func faint():
	is_fainted = true
	Global.send_monster_fainted.emit(self)
	# Waits for the currently opened text box to be closed
	await Global.battle_text_box_complete
	var ta: Array[String] = ["%s fainted!" % [name]]
	Global.send_battle_text_box.emit(ta, true)
	await Global.battle_text_box_complete
	Global.send_monster_death_experience.emit(EXPERIENCE_PER_LEVEL * level)
	
	
func heal(revives: bool) -> void:
	current_hitpoints = max_hitpoints
	if revives:
		is_fainted = false
	
	
func gain_exp(amount: int, in_battle: bool = false) -> void:
	if is_fainted:
		return
	var remaining_exp = amount
	while remaining_exp > 0:
		var exp_left = get_next_level_exp() - experience
		var exp_to_gain = min(remaining_exp, exp_left)
		remaining_exp -= exp_to_gain
		var current_exp = experience
		experience += exp_to_gain
		print("would gain %s exp, %s exp left" % [exp_to_gain, remaining_exp])
		print("exp would go frm %s -> %s" % [current_exp, experience])
		Global.monster_gained_experience.emit(self, exp_to_gain)
		if in_battle:
			print("in_battle")
			await Global.experience_animation_complete
		if experience >= get_next_level_exp():
			await gain_level()


func get_current_level_exp() -> int:
	return EXPERIENCE_PER_LEVEL * (level - 1)
	
	
func get_next_level_exp() -> int:
	return EXPERIENCE_PER_LEVEL * level


func gain_level(amount: int = 1) -> void:
	level += amount
	Global.monster_gained_level.emit(self, amount)
	var ta: Array[String] = ["%s leveled up to %s." % [name, level]]
	Global.send_battle_text_box.emit(ta, false)
	await Global.battle_text_box_complete
