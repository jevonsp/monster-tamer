class_name ActionList
extends Resource

@export var actions: Array[Action] = []


func run(actor: Monster, targets: Array[Monster]) -> Action.Flow:
	var final_flow := Action.Flow.NEXT
	var i := 0
	var skip_count := 0

	while i < actions.size():
		if skip_count > 0:
			skip_count -= 1
			i += 1
			continue
		var action := actions[i]
		if action == null:
			i += 1
			continue
		var before_flow := await action.before_trigger(actor, targets)
		match before_flow:
			Action.Flow.STOP:
				final_flow = Action.Flow.STOP
				break
			Action.Flow.SKIP:
				skip_count += 1
				i += 1
				continue
		var trigger_flow := await action.trigger(actor, targets)
		match trigger_flow:
			Action.Flow.STOP:
				final_flow = Action.Flow.STOP
				break
			Action.Flow.SKIP:
				skip_count += 1
				i += 1
				continue
		var after_flow := await action.after_trigger(actor, targets)
		match after_flow:
			Action.Flow.STOP:
				final_flow = Action.Flow.STOP
				break
			Action.Flow.SKIP:
				skip_count += 1
		i += 1

	return final_flow
