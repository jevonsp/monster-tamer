class_name NPCRespawnComponent
extends NPCComponent


func trigger(obj: Node) -> NPCComponent.Result:
	if obj.is_in_group("player") and obj.has_method("set_respawn_point"):
		obj.set_respawn_point()
	return NPCComponent.Result.CONTINUE
