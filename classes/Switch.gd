extends Resource
class_name Switch
@export_range(-5, 5) var priority: int = 5
var actor: Monster
var target: Monster
var out_unformatted: String = "Thats enough, %s!"
var in_unformatted: String = "Its your turn, %s"

func execute(old: Monster, new: Monster) -> void:
	var out_text: Array[String] = [out_unformatted % [old.name]]
	if old.is_able_to_fight:
		Global.send_text_box.emit(null, out_text, true, false, false)
		await Global.text_box_complete
	
	Global.send_monster_switch_out.emit(old)
	await Global.monster_switch_out_animation_complete
	
	Global.switch_monster_to_first.emit(new)
	
	Global.switch_battle_actors.emit(old, new)
	
	Global.send_monster_switch_in.emit(new)
	
	var in_text: Array[String] = [in_unformatted % [new.name]]
	Global.send_text_box.emit(null, in_text, false, false, false)
	await Global.text_box_complete
