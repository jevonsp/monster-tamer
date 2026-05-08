class_name TickWeatherAction
extends Action


func _trigger_impl(ctx: ActionContext) -> Flow:
	var weather = ctx.chassis.current_weather
	if not weather:
		return Flow.NEXT
	weather.turns_remaining -= 1
	return Flow.NEXT
