extends Resource
class_name Item

@export var name: String = ""
@export var ground_texture: Texture2D
@export var inventory_texture: Texture2D
@export var description: String = ""
@export_range(-5, 5) var priority: int = 0

@export var use_effect: ItemEffect
@export var held_effect: ItemEffect

func execute(actor: Monster, target: Monster) -> void:
	var pre_text: Array[String] = ["Used a %s on %s" % [name, target.name]]
	Global.send_battle_text_box.emit(pre_text, true)
	if use_effect:
		@warning_ignore("redundant_await")
		await use_effect.execute(actor, target)


func use(target: Monster) -> void:
	if use_effect:
		@warning_ignore("redundant_await")
		await use_effect.use(target)
		
		
func give(_target: Monster) -> void:
	pass
