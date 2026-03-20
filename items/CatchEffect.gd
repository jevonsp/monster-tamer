extends Resource
class_name CatchEffect

@export var catch_rate_modifier: float = 1.0

func execute(item: Item, actor: Monster, target: Monster, battle_context: BattleContext) -> void:
	await battle_context.play_item_throw(item)
	
	var result = target.attempt_catch(item, actor)
	var times = result["times"]
	
	await battle_context.play_ball_wiggle(times)
	
	var post_text: Array[String] = []
	
	if result["success"] == true:
		target.is_captured = true
		post_text.append("The enemy %s was captured!" % target.name)
		target.is_captured = true
		await battle_context.play_capture_animation(target)
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
	
	print("post_text: ", post_text)
	await battle_context.show_text(post_text, true)
