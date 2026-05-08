class_name MonsterRestorationService
extends RefCounted


func fully_heal_and_revive(monster: Monster) -> void:
	if monster.is_fainted:
		monster.is_fainted = false
	monster.current_hitpoints = monster.max_hitpoints


func restore_pp(monster: Monster) -> void:
	for move in monster.move_pp:
		if monster.move_pp[move] <= 0:
			monster.move_pp[move] = move.base_pp
