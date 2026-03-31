class_name Move
extends Resource

@export var name: String = ""
@export var type: TypeChart.Type
@export_range(0, 100, 5) var accuracy: int = 100
@export_range(-5, 5) var priority: int = 0
@export var animation: PackedScene
@export var is_self_targeting: bool = false
@export_multiline var description: String = ""
@export var effects: Array[MoveEffect] = []

var should_exit: bool = false


func execute(actor: Monster, target: Monster, battle_context: BattleContext) -> void:
	var missed: bool = calculate_miss(actor, target)

	if missed:
		var text_array: Array[String] = ["%s's attack missed!" % [actor]]
		await battle_context.show_text(text_array)
		return

	for effect in effects:
		if effect is MoveEffect:
			@warning_ignore("redundant_await")
			await effect.apply(actor, target, battle_context, name, animation)
			if should_exit:
				return


func calculate_miss(actor: Monster, target: Monster) -> bool:
	var adjusted_stage: int = clamp(
		actor.stat_stages_and_multis.stat_stages[Monster.Stat.ACCURACY]
		- target.stat_stages_and_multis.stat_stages[Monster.Stat.EVASION],
		-6,
		6,
	)
	var stat_stage_multi: float = MonsterStatTable.special_stat_multis[adjusted_stage]
	var stat_multi: float = (
		actor.stat_stages_and_multis.stat_multipliers[Monster.Stat.ACCURACY]
		* target.stat_stages_and_multis.stat_multipliers[Monster.Stat.EVASION]
	)
	var accuracy_float: float = accuracy / 100.0
	var final_accuracy: float = accuracy_float * stat_multi * stat_stage_multi

	return randf() >= final_accuracy
