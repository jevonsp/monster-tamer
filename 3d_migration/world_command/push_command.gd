class_name PushCommand
extends Command


func push_object(owner: Node) -> bool:
	if owner == null or not owner.has_method("push"):
		return false
	var player := PlayerContext3D.player
	if player == null:
		return false
	var push_direction: Vector3i = player.facing_grid
	return bool(owner.push(push_direction))


func _trigger_impl(owner) -> Flow:
	if owner == null:
		return Flow.STOP
	if await push_object(owner):
		return Flow.NEXT
	return Flow.STOP
