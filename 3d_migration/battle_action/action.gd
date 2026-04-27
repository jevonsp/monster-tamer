class_name Action
extends Resource

enum Flow { NEXT, SKIP, STOP }

@export var should_trigger: bool = true
@export var should_exit: bool = false


func before_trigger(owner: BattleChassis) -> Flow:
	if should_exit:
		return Flow.STOP
	if not should_trigger:
		return Flow.NEXT
	@warning_ignore("redundant_await")
	return await _before_impl(owner)


func trigger(owner: BattleChassis) -> Flow:
	if should_exit:
		return Flow.STOP
	if not should_trigger:
		return Flow.NEXT
	@warning_ignore("redundant_await")
	return await _trigger_impl(owner)


func after_trigger(owner: BattleChassis) -> Flow:
	if should_exit:
		return Flow.STOP
	if not should_trigger:
		return Flow.NEXT
	@warning_ignore("redundant_await")
	return await _after_impl(owner)


## Use this for conditional checks that completely stop the move
## ex: Misses / Status etc
func _before_impl(_owner) -> Flow:
	return Flow.NEXT


## Use this for chance based applicators
## ex: ConditionalCommand
func _trigger_impl(_owner) -> Flow:
	return Flow.NEXT


## Use this for recoil, side effects
## ex: Damage, heal
func _after_impl(_owner) -> Flow:
	return Flow.NEXT
