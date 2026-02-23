extends Resource
class_name Item
@export var name: String = ""
@export var ground_texture: Texture2D
@export var inventory_texture: Texture2D
@export var description: String = ""
@export var is_held: bool = false
@export var is_usable: bool = false
@export var is_healing: bool = false
@export var is_revival: bool = false
@export var base_healing: int = 20


func execute(target: Monster) -> void:
	"""In-battle"""
	var pre_text: Array[String] = ["Used a %s on %s" % [name, target.name]]
	
	Global.send_battle_text_box.emit(pre_text, true)
	var post_text: Array[String]
	if is_healing:
		target.heal(base_healing, is_revival)
		await Global.hitpoints_animation_complete
		post_text = ["It healed %s hitpoints!" % [base_healing]]
	if is_revival:
		post_text = ["%s was revived!" % [target.name]]
	
	Global.send_battle_text_box.emit(post_text, false)
	await Global.text_box_complete


func use(target: Monster) -> void:
	"""Out-of-battle"""
	print("OOB %s used on %s" % [name, target.name])
	if is_healing:
		if target.current_hitpoints == target.max_hitpoints:
			return
		target.heal(base_healing, is_revival)
		await Global.hitpoints_animation_complete


func give(_target: Monster) -> void:
	pass
