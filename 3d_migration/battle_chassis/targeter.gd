class_name Targeter
extends RefCounted

var chassis: BattleChassis = null
var actor: Monster = null
var player_actors: Array[Monster] = []
var enemy_actors: Array[Monster] = []
var target_type: Choice.Target = Choice.Target.ENEMY


func get_allowed() -> Array[Monster]:
	var allowed_targets: Array[Monster] = []

	match target_type:
		Choice.Target.ENEMY:
			if chassis.is_player_actor(actor):
				allowed_targets.append(enemy_actors)
			else:
				allowed_targets.append(player_actors)
		Choice.Target.USER:
			allowed_targets.append(actor)
		Choice.Target.ALLIES:
			if chassis.is_player_actor(actor):
				allowed_targets.append(player_actors)
			else:
				allowed_targets.append(enemy_actors)
		Choice.Target.ENEMIES:
			if chassis.is_player_actor(actor):
				allowed_targets.append(enemy_actors)
			else:
				allowed_targets.append(player_actors)
		Choice.Target.OTHERS:
			for monster in player_actors:
				if monster == actor:
					pass
				allowed_targets.append(monster)
			for monster in enemy_actors:
				if monster == actor:
					pass
				allowed_targets.append(monster)
		Choice.Target.ALL:
			allowed_targets.append(player_actors)
			allowed_targets.append(enemy_actors)
		_:
			pass

	return allowed_targets
