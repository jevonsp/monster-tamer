extends NPCComponent
class_name NPCRespawnComponent

func trigger(obj: Node) -> void:
	if obj.is_in_group("player") and obj.has_method("set_respawn_point"):
		obj.set_respawn_point()
