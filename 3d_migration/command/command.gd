class_name Command
extends Resource

## How the interact machine moves after a phase.
## NEXT: run the next phase, or the next command after *after_trigger*.
## STOP: end this command list; no more commands in this interaction.
enum Flow { NEXT, STOP }

@export var should_trigger: bool = true
@export var should_exit: bool = false


func before_trigger(owner: Node) -> Flow:
	if should_exit:
		return Flow.STOP
	if not should_trigger:
		return Flow.NEXT
	@warning_ignore("redundant_await")
	return await _before_impl(owner)


func trigger(owner: Node) -> Flow:
	if should_exit:
		return Flow.STOP
	if not should_trigger:
		return Flow.NEXT
	@warning_ignore("redundant_await")
	return await _trigger_impl(owner)


func after_trigger(owner: Node) -> Flow:
	if should_exit:
		return Flow.STOP
	if not should_trigger:
		return Flow.NEXT
	@warning_ignore("redundant_await")
	return await _after_impl(owner)


func _before_impl(owner) -> Flow:
	return Flow.NEXT


func _trigger_impl(owner) -> Flow:
	return Flow.NEXT


func _after_impl(owner) -> Flow:
	return Flow.NEXT
