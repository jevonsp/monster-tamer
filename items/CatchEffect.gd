class_name CatchEffect
extends Resource

@export var catch_rate_modifier: float = 1.0


func execute(item: Item, actor: Monster, target: Monster, battle_context: BattleContext) -> void:
	await battle_context.play_item_throw(item)
	await battle_context.play_capture_animation()

	var result = target.attempt_catch(item, actor)
	var times = result["times"]

	await battle_context.play_ball_wiggle(times)

	var post_text: Array[String] = []

	if result["success"] == true:
		target.is_captured = true
		Party.capture_monster.emit(target)
		post_text.append("The enemy %s was captured!" % target.name)
	else:
		match times:
			0:
				post_text.append("The enemy escaped with no effort at all!")
			1:
				post_text.append("Dang, it escaped easily!")
			2:
				post_text.append("We almost got it that time!")
			3:
				post_text.append("Oh no! It was SO close!")

		await battle_context.play_escape_animation()

	await battle_context.show_text(post_text, true)
