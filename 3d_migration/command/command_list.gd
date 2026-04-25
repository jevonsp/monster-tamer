class_name CommandList
extends Resource

@export var commands: Array[Command] = []


## Runs *commands* in order. The first *STOP* in before → trigger → after ends the whole list.
func run(owner: Node) -> void:
	PlayerContext3D.toggle_player.emit(false)
	PlayerContext3D.player.clear_inputs()

	for command: Command in commands:
		if command == null:
			continue
		if await command.before_trigger(owner) == Command.Flow.STOP:
			return
		if await command.trigger(owner) == Command.Flow.STOP:
			return
		if await command.after_trigger(owner) == Command.Flow.STOP:
			return

	PlayerContext3D.player.clear_inputs()
	PlayerContext3D.toggle_player.emit(true)
