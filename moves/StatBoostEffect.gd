extends MoveEffect
class_name StatBoostEffect

@export var stat: Monster.Stat = Monster.Stat.ATTACK
@export_range(-6, 6) var stage_amount: int = 1
@export var is_self_targeting: bool = true

func apply(
	actor: Monster,
	target: Monster,
	context: BattleContext,
	_move_name: String = "",
	_animation: PackedScene = null
) -> void:
	var monster = actor if is_self_targeting else target
	var result = monster.boost_stat(stat, stage_amount)
	var ta: Array[String]
	var stat_string: String = Monster.Stat.keys()[stat].to_lower()
	match result:
		Monster.BoostApplyResult.APPLIED:
			var word = "rose" if stage_amount > 0 else "fell"
			ta = ["{name}'s {stat} {word} by {amount} {stages}".format({
				"name": monster.name,
				"stat": stat_string,
				"word": word,
				"amount": abs(stage_amount),
				"stages": _stage_pluralizer()
			})]
			await context.play_stat_animation(monster, stat, stage_amount)
		Monster.BoostApplyResult.BLOCKED:
			var word = "higher" if stage_amount > 0 else "lower"
			ta = ["{name}'s {stat} can go no {word}!".format({
				"name": monster.name,
				"stat": stat_string,
				"word": word,
			})]
			
	Global.send_text_box.emit(null, ta, true, false, false)
	await Global.text_box_complete
	

func _stage_pluralizer() -> String:
	if stage_amount > 1:
		return "stages"
	return "stage"
