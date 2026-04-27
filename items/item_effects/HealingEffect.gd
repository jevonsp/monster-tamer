class_name HealingEffect
extends ItemEffect

@export var base_healing: int = 20
@export var revives: bool = false


func execute(_actor: Monster, target: Monster, battle_context: BattleContext) -> void:
	await target.heal(base_healing, revives)

	var post_text: Array[String] = [""]
	if revives:
		post_text[0] += "%s was revived!\n" % [target.name]
	if base_healing > 0:
		post_text[0] += "It healed %s hitpoints!" % [base_healing]

	await battle_context.show_text(post_text, true)


func use(target: Monster) -> bool:
	if target.current_hitpoints == target.max_hitpoints and not revives:
		var fail_text: Array[String] = ["%s is already full health!" % [target.name]]
		Ui.send_text_box.emit(null, fail_text, true, false, false)
		await Ui.text_box_complete
		return false
	target.heal(base_healing, revives)
	await Battle.hitpoints_animation_complete
	var success_text: Array[String] = ["%s gained %s hitpoints." % [target.name, base_healing]]
	Ui.send_text_box.emit(null, success_text, true, false, false)
	await Ui.text_box_complete
	return true
