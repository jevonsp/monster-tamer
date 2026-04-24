class_name Command
extends Resource

## How the interact machine moves after a phase.
## NEXT: run the next phase, or the next command after *after_trigger*.
## STOP: end this command list; no more commands in this interaction.
enum Flow { NEXT, STOP }

@export var should_trigger: bool = true
@export var should_exit: bool = false


func before_trigger() -> Flow:
	if should_exit:
		return Flow.STOP
	if not should_trigger:
		return Flow.NEXT
	@warning_ignore("redundant_await")
	return await _before_impl()


func _before_impl() -> Flow:
	return Flow.NEXT


func trigger() -> Flow:
	if should_exit:
		return Flow.STOP
	if not should_trigger:
		return Flow.NEXT
	@warning_ignore("redundant_await")
	return await _trigger_impl()


func _trigger_impl() -> Flow:
	return Flow.NEXT


func after_trigger() -> Flow:
	if should_exit:
		return Flow.STOP
	if not should_trigger:
		return Flow.NEXT
	@warning_ignore("redundant_await")
	return await _after_impl()


func _after_impl() -> Flow:
	return Flow.NEXT
