class_name Command
extends Resource

@export var should_trigger: bool = true
@export var should_exit: bool = false


func before_trigger() -> bool:
	if should_exit:
		return false
	if not should_trigger:
		return true

	# Do pre trigger stuff here

	return true


func trigger() -> bool:
	if should_exit:
		return false
	if not should_trigger:
		return true

	# Do command here

	return true


func after_trigger() -> bool:
	if should_exit:
		return false
	if not should_trigger:
		return true

	# Clean up command here

	return true
