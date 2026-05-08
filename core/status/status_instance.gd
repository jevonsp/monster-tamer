class_name StatusInstance
extends Resource

@export var data: StatusData
@export var source: Monster = null
@export var stacks: int = 1
## Per-instance scratchpad for hook ActionLists (e.g. confusion turn counter).
@export var state: Dictionary = { }

var turns_remaining: int = -1


static func from_data(p_data: StatusData, p_source: Monster = null) -> StatusInstance:
	var instance := StatusInstance.new()
	instance.data = p_data
	instance.source = p_source
	instance.turns_remaining = p_data.default_duration if p_data != null else -1
	return instance
