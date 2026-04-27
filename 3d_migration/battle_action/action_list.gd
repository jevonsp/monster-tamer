class_name ActionList
extends Resource

@export var actions: Array[Action] = []


func run(owner: Node) -> Action.Flow:
	var final_flow := Action.Flow.NEXT
	PlayerContext3D.toggle_player.emit(false)
	PlayerContext3D.player.clear_inputs()

	for action: Action in actions:
		if action == null:
			continue
		var before_flow := await action.before_trigger(owner)
		if before_flow == Action.Flow.STOP:
			final_flow = Action.Flow.STOP
			break
		var trigger_flow := await action.trigger(owner)
		if trigger_flow == Action.Flow.STOP:
			final_flow = Action.Flow.STOP
			break
		var after_flow := await action.after_trigger(owner)
		if after_flow == Action.Flow.STOP:
			final_flow = Action.Flow.STOP
			break

	PlayerContext3D.player.clear_inputs()
	PlayerContext3D.toggle_player.emit(true)
	return final_flow
