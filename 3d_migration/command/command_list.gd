class_name CommandList
extends Resource

@export var commands: Array[Command] = []


## Runs *commands* in order. The first *STOP* in before → trigger → after ends the whole list.
func run() -> void:
	PlayerContext3D.toggle_player.emit(false)

	for command: Command in commands:
		if command == null:
			continue
		if await command.before_trigger() == Command.Flow.STOP:
			return
		if await command.trigger() == Command.Flow.STOP:
			return
		if await command.after_trigger() == Command.Flow.STOP:
			return

	PlayerContext3D.toggle_player.emit(true)
