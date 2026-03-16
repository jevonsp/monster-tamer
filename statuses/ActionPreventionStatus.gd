extends StatusData
class_name ActionPreventionStatus

@export var action_prevention_percent: float = 1.0

func on_apply(_instance: StatusInstance, owner: Monster, context: BattleContext) -> void:
	var ta: Array[String] = \
			["%s was afflicted with %s, it may be unable to act!" % [owner.name, status_name]]
	await context.show_text(ta)
	owner.is_able_to_act = false


func on_turn_start(instance: StatusInstance, owner: Monster, context: BattleContext) -> void:
	var ta: Array[String] = []
	var chance = randf()
	
	if chance > action_prevention_percent:
		ta = ["%s's %s wore off!" % [owner.name, status_name]]
		await context.show_text(ta)
		owner.is_able_to_act = true
		instance.expire()
		return
		
	ta = ["%s was unable to act due to %s!" % [owner.name, status_name]]
	await context.show_text(ta)


func on_remove(_instance: StatusInstance, owner: Monster, _context: BattleContext) -> void:
	owner.is_able_to_act = true
