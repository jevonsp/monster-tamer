extends ItemEffect
class_name HealingEffect

@export var base_healing: int = 20
@export var revives: bool = false

func execute(_actor: Monster, target: Monster) -> void:
	target.heal(base_healing, revives)
	await Global.hitpoints_animation_complete
	var post_text: Array[String]
	if revives:
		post_text = ["%s was revived!" % [target.name]]
	else:
		post_text = ["It healed %s hitpoints!" % [base_healing]]
	Global.send_battle_text_box.emit(post_text, false)
	await Global.text_box_complete


func use(target: Monster) -> void:
	if target.current_hitpoints == target.max_hitpoints and not revives:
		var fail_text: Array[String] = ["%s is already full health!" % [target.name]]
		Global.send_overworld_text_box.emit(null, fail_text, true, false, false)
		await Global.text_box_complete
		return
	target.heal(base_healing, revives)
	await Global.hitpoints_animation_complete
	var success_text: Array[String] = ["%s gained %s hitpoints." % [target.name, base_healing]]
	Global.send_overworld_text_box.emit(null, success_text, true, false, false)
	await Global.text_box_complete
