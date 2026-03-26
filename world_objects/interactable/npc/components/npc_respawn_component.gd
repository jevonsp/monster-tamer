class_name NPCRespawnComponent
extends NPCComponent

@export var is_healing: bool = false


func trigger(obj: Node) -> void:
	if obj.is_in_group("player") and obj.has_method("set_respawn_point"):
		obj.set_respawn_point()
		if is_healing:
			obj.party_handler.fully_heal_and_revive_party()
