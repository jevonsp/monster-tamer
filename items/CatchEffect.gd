extends Resource
class_name CatchEffect

@export var catch_rate_modifier: float = 1.0

func execute(item: Item, actor: Monster, target: Monster) -> void:
	Global.send_item_throw_animation.emit(item)
	await Global.item_animation_complete
	
	var result = target.attempt_catch(item, actor)
	var times = result["times"]
	
	Global.send_item_wiggle.emit(times)
	await Global.wiggle_animation_complete
	
	var post_text: Array[String] = []
	
	if result["success"] == true:
		target.is_captured = true
		post_text.append("The enemy %s was captured!" % target.name)
		Global.send_capture_animation.emit()
		Global.capture_monster.emit(target)
	else:
		Global.send_escape_animation.emit()
		match times:
			0:
				post_text.append("The enemy escaped with no effort at all!")
			1:
				post_text.append("Dang, it escaped easily!")
			2:
				post_text.append("We almost got it that time!")
			3:
				post_text.append("Oh no! It was SO close!")
				
	await Global.capture_or_escape_animation_complete
	
	Global.send_text_box.emit(post_text, false)
	await Global.text_box_complete
