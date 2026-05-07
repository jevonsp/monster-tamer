class_name SetBlockAction
extends Action

## Sets ctx.data["block_action"] = true with the given chance. Used by
## paralyze/sleep-style statuses inside on_potential_block hook lists. Returns
## Flow.STOP on success so subsequent actions in the same hook list don't run.
@export_range(0.0, 1.0) var chance: float = 1.0


func _trigger_impl(ctx: ActionContext) -> Flow:
	if chance < 1.0 and randf() > chance:
		return Flow.NEXT
	ctx.data["block_action"] = true
	return Flow.STOP
