class_name SetSubstituteActionList
extends Action

## Sets ctx.data["substitute_action_list"] to the configured ActionList with
## the given chance. Used by confusion-style statuses inside on_potential_block
## hook lists. Returns Flow.STOP on success so subsequent actions don't run.
## First-writer-wins: if substitute_action_list is already set, this is a no-op.
@export var substitute: ActionList = null
@export_range(0.0, 1.0) var chance: float = 1.0


func _trigger_impl(ctx: ActionContext) -> Flow:
	if substitute == null:
		return Flow.NEXT
	if ctx.data.has("substitute_action_list"):
		return Flow.NEXT
	if chance < 1.0 and randf() > chance:
		return Flow.NEXT
	ctx.data["substitute_action_list"] = substitute
	return Flow.STOP
