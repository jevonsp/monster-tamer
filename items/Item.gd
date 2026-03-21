extends Resource
class_name Item

@export var name: String = ""
@export var ground_texture: Texture2D
@export var inventory_texture: Texture2D
@export var battle_texture: Texture2D
@export_multiline var description: String = ""
@export_range(-5, 5) var priority: int = 0

@export var use_effect: ItemEffect
@export var held_effect: HeldEffect
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


func give(target: Monster) -> void:
	if held_effect:
		var success = target.hold_item(self)
		var ta: Array[String] 
		if success:
			ta = ["Gave %s to %s to hold." % [self.name, target.name]]
			Global.send_text_box.emit(null, ta, false, false, false)
			await Global.text_box_complete
		else:
			ta = ["%s is already holding %s. Swap items?"]
			Global.send_text_box.emit(null, ta, false, true, false)
			var answer = await Global.text_box_complete
			if answer:
				await target.swap_items(self)
				ta = ["Gave %s to %s to hold." % [self.name, target.name]]
				Global.send_text_box.emit(null, ta, false, false, false)
				await Global.text_box_complete
			else:
				return
