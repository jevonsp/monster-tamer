class_name Item
extends Resource

enum Type { USE, BALL, HELD, KEY }

@export var name: String = ""
@export var item_type: Type = Type.USE
@export_multiline var description: String = ""
@export var is_multi_use: bool = false
@export_range(0, 999_999_999, 50) var price: int = 100
@export_range(-5, 5) var priority: int = 0
@export var use_effect: ItemEffect
@export var held_effect: HeldEffect
@export var catch_effect: CatchEffect
@export_subgroup("Textures")
@export var ground_texture: Texture2D
@export var inventory_texture: Texture2D
@export var battle_texture: Texture2D


func execute(actor: Monster, target: Monster, battle_context: BattleContext) -> void:
	await battle_context.show_item_used_text(self, actor, target)

	if catch_effect:
		@warning_ignore("redundant_await")
		await catch_effect.execute(self, actor, target, battle_context)
	elif use_effect:
		@warning_ignore("redundant_await")
		await use_effect.execute(actor, target, battle_context)


func use(target: Monster) -> bool:
	if use_effect:
		@warning_ignore("redundant_await")
		return await use_effect.use(target)
	return false


func give(target: Monster) -> bool:
	if held_effect == null or target == null:
		return false

	return target.hold_item(self)


func get_display_name() -> String:
	return name


func get_display_description() -> String:
	return description
