extends Resource
class_name Move

@export var name: String = ""
@export var animation: PackedScene
@export var base_power: int = 5
@export_range(-5, 5) var priority: int = 0
@export var is_self_targeting: bool = false
@export_multiline var description: String = ""


func execute(actor: Monster, target: Monster):
	print("%s would use %s on %s" % [actor.name, name, target.name])
