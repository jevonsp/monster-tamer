class_name CaptureHelper
extends RefCounted


static func compute_capture_event(
		attacker: Monster,
		target: Monster,
		catch_rate: float,
) -> Dictionary:
	var critical: bool

	var times: int
	var is_successful: bool
	return {
		"times": times,
		"success": is_successful,
	}
