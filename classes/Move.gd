extends Resource
class_name Move

@export var name: String = ""
@export var animation: PackedScene
@export var base_power: int = 5
@export_range(-5, 5) var priority: int = 0
@export var is_self_targeting: bool = false
@export_multiline var description: String = ""


func execute(actor: Monster, target: Monster):
	var text: Array[String] = ["%s used %s on %s" % [actor.name, name, target.name]]
	Global.send_text_box.emit(text, true)
	Global.send_move_animation.emit(animation)
	await Global.move_animation_complete
	print("got move_animation_complete")
