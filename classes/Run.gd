class_name Run
extends Resource

@export_range(-5, 5) var priority: int = 0


func execute(actor: Monster, target: Monster, battle_context: BattleContext) -> void:
	var attempts = battle_context.battle.turn_executor.run_count
	var odds_escape: int = (actor.speed * 32.0) / (target.speed / 4.0) + (30 * attempts)
	var chance_escape: int = randi_range(0, 255)

	var is_escape = odds_escape > chance_escape
	var text_array: Array[String] = [""]

	battle_context.handler.is_escaped = is_escape

	if is_escape:
		text_array[0] = "%s managed to escape." % actor.name
		await battle_context.show_text(text_array)
		await battle_context.battle.visibility_focus_handler.animation_player.play_monster_switch_out(actor)
	else:
		text_array[0] = "Oh no! %s couldn't escape!" % actor.name
		await battle_context.show_text(text_array)
