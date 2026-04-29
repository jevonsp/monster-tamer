class_name DamageAction
extends Action

@export var base_power: int = 30
@export var type: TypeChart.Type = TypeChart.Type.NONE
@export var recoil_percent: float = 0.0


func _trigger_impl(ctx: ActionContext) -> Flow:
	if ctx.choice.targets.is_empty():
		return Flow.NEXT

	var target: Monster = ctx.choice.targets[0]
	var from_hp := target.current_hitpoints
	var dmg := _calc_damage(ctx.choice.actor, target)
	var critical := _calc_critical(ctx.choice.actor, target)
	if critical:
		dmg *= 2
	var efficacy := _calc_efficacy(ctx.choice.actor, target)
	dmg = round(dmg * efficacy)
	target.current_hitpoints = maxi(0, from_hp - dmg)

	var target_fainted := target.current_hitpoints <= 0
	if target_fainted:
		target.is_fainted = true

	ctx.data["last_hp_change"] = {
		"target": target,
		"from": from_hp,
		"to": target.current_hitpoints,
		"damage": dmg,
		"efficacy": efficacy,
		"critical": critical,
		"target_fainted": target_fainted,
	}

	return Flow.NEXT


func _calc_efficacy(_attacker: Monster, _target: Monster) -> float:
	return 1.0


func _calc_damage(_attacker: Monster, _target: Monster) -> int:
	return base_power


func _calc_critical(_attacker: Monster, _target: Monster) -> bool:
	return false


func _calc_recoil() -> int:
	return 0
