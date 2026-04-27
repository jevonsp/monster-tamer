class_name Targeter
extends Resource


func resolve_user(battle_chassis: BattleChassis) -> Monster:
	return battle_chassis.current_actor


func resolve_targets(choice: Choice, battle_chassis: BattleChassis):
	match choice.type:
		Choice.Type.MOVE, Choice.Type.SWITCH:
			if battle_chassis.current_actor.is_player_monster:
				return battle_chassis.current_actor.name
			else:
				if battle_chassis.trainer:
					return "enemy %s" % battle_chassis.trainer.name
				else:
					return "wild %s" % battle_chassis.current_actor
		Choice.Type.ITEM:
			if battle_chassis.current_actor.is_player_monster:
				return "you"
			else:
				if battle_chassis.trainer:
					return "enemy %s" % battle_chassis.trainer.name
				else:
					return "wild %s" % battle_chassis.current_actor
		Choice.Type.FLEE:
			if choice.targets.size() <= 1:
				return battle_chassis.enemy_actors[0].name
			else:
				return "the enemies"
