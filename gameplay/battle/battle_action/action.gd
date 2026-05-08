class_name Action
extends Resource

enum Flow { NEXT, SKIP, STOP }

@export var should_trigger: bool = true
@export var should_exit: bool = false


func before_trigger(ctx: ActionContext) -> Flow:
	if should_exit:
		return Flow.STOP
	if not should_trigger:
		return Flow.NEXT
	@warning_ignore("redundant_await")
	return await _before_impl(ctx)


func trigger(ctx: ActionContext) -> Flow:
	if should_exit:
		return Flow.STOP
	if not should_trigger:
		return Flow.NEXT
	@warning_ignore("redundant_await")
	return await _trigger_impl(ctx)


func after_trigger(ctx: ActionContext) -> Flow:
	if should_exit:
		return Flow.STOP
	if not should_trigger:
		return Flow.NEXT
	@warning_ignore("redundant_await")
	return await _after_impl(ctx)


## Use this for conditional checks that completely stop the move
## ex: Invulnerable, already used the move, etc
func _before_impl(_ctx: ActionContext) -> Flow:
	return Flow.NEXT


## Use this for chance based applicators
## ex: ConditionalCommand
func _trigger_impl(_ctx: ActionContext) -> Flow:
	return Flow.NEXT


## Use this for recoil, side effects
## ex: Damage, heal
func _after_impl(_ctx: ActionContext) -> Flow:
	return Flow.NEXT
