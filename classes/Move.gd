class_name Move
extends Resource

@export var name: String = ""
@export var animation: PackedScene
@export var base_power: int = 2
@export_range(-5, 5) var priority: int = 0
@export var is_self_targeting: bool = false
@export_multiline var description: String = ""


func execute(actor: Monster, target: Monster):
	var damage = base_power
	var pre_text: Array[String] = ["%s used %s on %s" % [actor.name, name, target.name]]
	
	Global.send_battle_text_box.emit(pre_text, true)
	
	Global.send_move_animation.emit(animation)
	await Global.move_animation_complete
	
	Global.send_sprite_shake.emit(target)
	
	target.take_damage(damage)
	await Global.hitpoints_animation_complete
	
	var post_text: Array[String] = ["It dealt %s damage!" % [damage]]
	
	Global.send_battle_text_box.emit(post_text, false)
	await Global.battle_text_box_complete
