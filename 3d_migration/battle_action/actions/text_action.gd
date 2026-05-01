class_name TextAction
extends Action

@export_multiline() var text: Array[String] = ["{actor} used {move} on {target}!"]
@export var is_autocomplete: bool = false
@export var needs_formatting: bool = false


func _trigger_impl(ctx: ActionContext) -> Flow:
	var lines := text
	if needs_formatting:
		lines = _format_text(ctx.choice)
	var new_ctx = ctx.fork()
	@warning_ignore("redundant_await")
	await ctx.presenter.show_text(new_ctx, lines, is_autocomplete)
	return Flow.NEXT


func _format_text(choice: Choice) -> Array[String]:
	var actor := "Player"
	if choice.actor != null:
		actor = choice.actor.name
	var target := "target"
	if not choice.targets.is_empty():
		target = choice.targets[0].name
	var move_name := ""
	if choice.action_or_list != null and "name" in choice.action_or_list:
		move_name = choice.action_or_list.name
	var fmt: Array[String] = []
	for s in text:
		fmt.append(
			s.format(
				{
					"actor": actor,
					"move": move_name,
					"target": target,
				},
			),
		)
	return fmt
