extends Resource
class_name Item

@export var name: String = ""
@export var ground_texture: Texture2D
@export var inventory_texture: Texture2D
@export var battle_texture: Texture2D
@export_multiline var description: String = ""
@export_range(-5, 5) var priority: int = 0

@export var use_effect: ItemEffect
@export var held_effect: ItemEffect
@export var catch_effect: CatchEffect


func execute(actor: Monster, target: Monster) -> void:
	var pre_text: Array[String] = ["Used a %s on %s" % [name, target.name]]
	Global.send_battle_text_box.emit(pre_text, true)
	await Global.text_box_complete
	
	if catch_effect:
		@warning_ignore("redundant_await")
		await catch_effect.execute(self, actor, target)
	elif use_effect:
		@warning_ignore("redundant_await")
		await use_effect.execute(actor, target)


func use(target: Monster) -> void:
	if use_effect:
		@warning_ignore("redundant_await")
		await use_effect.use(target)


func give(_target: Monster) -> void:
	print("would give here")
