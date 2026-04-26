class_name CommandList
extends Resource

@export var commands: Array[Command] = []

## Runs *commands* in order. The first *STOP* in before → trigger → after ends the whole list.
func run(owner: Node) -> Command.Flow:
	var final_flow := Command.Flow.NEXT
	PlayerContext3D.toggle_player.emit(false)
	PlayerContext3D.player.clear_inputs()

	for command: Command in commands:
		if command == null:
			continue
		var before_flow := await command.before_trigger(owner)
		if before_flow == Command.Flow.STOP:
			final_flow = Command.Flow.STOP
			break
		var trigger_flow := await command.trigger(owner)
		if trigger_flow == Command.Flow.STOP:
			final_flow = Command.Flow.STOP
			break
		var after_flow := await command.after_trigger(owner)
		if after_flow == Command.Flow.STOP:
			final_flow = Command.Flow.STOP
			break

	PlayerContext3D.player.clear_inputs()
	PlayerContext3D.toggle_player.emit(true)
	return final_flow
