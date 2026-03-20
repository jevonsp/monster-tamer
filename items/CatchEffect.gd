extends Resource
class_name CatchEffect

@export var catch_rate_modifier: float = 1.0

func execute(item: Item, actor: Monster, target: Monster, battle_context: BattleContext) -> void:
	print_debug(
		"BATTLE: catch_effect start item=%s actor=%s target=%s"
		% [item, actor.name if actor else "null", target.name if target else "null"]
	)
	await battle_context.play_item_throw(item)
	print_debug("BATTLE: catch_effect throw complete target=%s" % [target.name if target else "null"])
	await battle_context.play_capture_animation()
	print_debug("BATTLE: catch_effect capture animation complete target=%s" % [target.name if target else "null"])
	
	var result = target.attempt_catch(item, actor)
	var times = result["times"]
	print_debug(
		"BATTLE: catch_effect roll result success=%s times=%s target=%s"
		% [result["success"], times, target.name if target else "null"]
	)
	
	await battle_context.play_ball_wiggle(times)
	print_debug("BATTLE: catch_effect wiggle complete times=%s target=%s" % [times, target.name if target else "null"])
	
	var post_text: Array[String] = []
	
	if result["success"] == true:
		target.is_captured = true
		Global.capture_monster.emit(target)
		print_debug("BATTLE: catch_effect success target=%s" % [target.name if target else "null"])
		post_text.append("The enemy %s was captured!" % target.name)
	else:
		print_debug("BATTLE: catch_effect failure target=%s times=%s" % [target.name if target else "null", times])
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
		print_debug("BATTLE: catch_effect escape animation complete target=%s" % [target.name if target else "null"])

	print_debug("BATTLE: catch_effect show text lines=%s" % [post_text])
	await battle_context.show_text(post_text, true)
	print_debug("BATTLE: catch_effect end target=%s success=%s" % [target.name if target else "null", result["success"]])
