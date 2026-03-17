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


func execute(actor: Monster, target: Monster, battle_context: BattleContext) -> void:
	await battle_context.show_item_used_text(self, actor, target)
	
	if catch_effect:
		@warning_ignore("redundant_await")
		await catch_effect.execute(self, actor, target, battle_context)
	elif use_effect:
		@warning_ignore("redundant_await")
		await use_effect.execute(actor, target, battle_context)


func use(target: Monster) -> void:
	if use_effect:
		@warning_ignore("redundant_await")
		await use_effect.use(target)


func give(_target: Monster) -> void:
	print_debug("would give here")
