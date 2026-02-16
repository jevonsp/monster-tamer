extends Resource
class_name Item
@export var is_held: bool = false
@export var is_healing: bool = false

func use(_target: Monster) -> void:
	"""Out-of-battle"""
	pass


func execute(_target: Monster) -> void:
	"""In-battle"""
	pass


func give(_target: Monster) -> void:
	pass
