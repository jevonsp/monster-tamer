extends Node

@onready var summary: Control = $".."


func clear_monster() -> void:
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

	summary.gender_label.text = "TBD"
	summary.name_label.text = monster.name
	summary.level_label.text = "Lvl. %s" % [monster.level]

	summary.hp_bar.max_value = monster.max_hitpoints
	summary.hp_bar.value = monster.current_hitpoints
	summary.hp_bar.actor = monster

	var min_exp: int = Monster.EXPERIENCE_PER_LEVEL * (monster.level - 1)
	var max_exp: int = Monster.EXPERIENCE_PER_LEVEL * monster.level

	summary.exp_bar.max_value = max_exp
	summary.exp_bar.min_value = min_exp
	summary.exp_bar.value = monster.experience
	summary.exp_bar.actor = monster

	summary.portrait.texture = monster.monster_data.texture
	summary.description_label.text = "TBD"

	summary.stat_label_0.text = "TBD: "
	summary.stat_label_1.text = "TBD: "
	summary.stat_label_2.text = "TBD: "
	summary.stat_label_3.text = "TBD: "
	summary.stat_label_4.text = "TBD: "
	summary.stat_label_5.text = "TBD: "

	var panel_index := 0
	for move in monster.moves:
		if panel_index >= summary.move_panels.size():
			break
		summary.move_panels[panel_index].move = move
		summary.move_panels[panel_index].setup()
		panel_index += 1
