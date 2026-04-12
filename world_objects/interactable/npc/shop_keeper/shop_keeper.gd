@tool
class_name ShopKeeper
extends NPC


func _ready() -> void:
	if not Engine.is_editor_hint():
		_remove_default_body_collision()
	super._ready()


func _remove_default_body_collision() -> void:
	for child in get_children():
		if child is CollisionShape2D and (child as Node2D).position.is_equal_approx(Vector2(8, 8)):
			child.free()
			return
