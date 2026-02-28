extends Resource
@export_range(-5, 5) var priority: int = 5

func execute(old: Monster, new: Monster) -> void:
	var out_text: Array[String] = ["Thats enough, %s!" % [old.name]]
	Global.send_battle_text_box.emit(out_text, true)
	await Global.text_box_complete
	
	Global.send_monster_switch_out.emit(old)
	await Global.monster_switch_out_animation_complete
	
	Global.switch_battle_actors.emit(old, new)
	
	Global.send_monster_switch_in.emit(new)
	
	var in_text: Array[String] = ["Its your turn, %s" % [new.name]]
	Global.send_battle_text_box.emit(in_text, false)
	await Global.text_box_complete
