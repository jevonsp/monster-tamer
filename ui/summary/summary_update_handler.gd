extends Node

@onready var summary: Control = $".."
@onready var _actor_nodes: Array[Node] = [
	summary.hp_bar,
	summary.exp_bar,
	summary.portrait,
]


func clear_monster() -> void:
	_bind_actor(null)
	for label in summary.labels:
		label.text = ""

	for panel in summary.move_panels:
		panel.clear()

	summary.portrait.texture = null
	for bar in [summary.hp_bar, summary.exp_bar]:
		bar.max_value = 100
		bar.value = 0


func display_monster(monster: Monster) -> void:
	clear_monster()
	if monster == null:
		return
	_bind_actor(monster)

	summary.gender_label.text = MonsterData.Gender.keys()[monster.gender].to_lower().capitalize()
	summary.name_label.text = monster.name
	summary.level_label.text = "Lvl. %s" % [monster.level]

	summary.hp_bar.max_value = monster.max_hitpoints
	summary.hp_bar.value = monster.current_hitpoints

	var min_exp: int = Monster.EXPERIENCE_PER_LEVEL * (monster.level - 1)
	var max_exp: int = Monster.EXPERIENCE_PER_LEVEL * monster.level

	summary.exp_bar.max_value = max_exp
	summary.exp_bar.min_value = min_exp
	summary.exp_bar.value = monster.experience

	summary.portrait.texture = monster.monster_data.texture
	summary.description_label.text = monster.monster_data.description

	summary.stat_label_0.text = "HP: %s" % [monster.max_hitpoints]
	summary.stat_label_1.text = "Atk: %s" % [monster.attack]
	summary.stat_label_2.text = "Def: %s" % [monster.defense]
	summary.stat_label_3.text = "SpA: %s" % [monster.special_attack]
	summary.stat_label_4.text = "SpD: %s" % [monster.special_defense]
	summary.stat_label_5.text = "Spe: %s" % [monster.speed]

	var panel_index := 0
	for move in monster.moves:
		if panel_index >= summary.move_panels.size():
			break
		summary.move_panels[panel_index].move = move
		summary.move_panels[panel_index].setup()
		panel_index += 1


func _bind_actor(actor: Monster) -> void:
	for node: Node in _actor_nodes:
		if node == null:
			continue
		if node.has_method(&"set_actor"):
			node.set_actor(actor)
