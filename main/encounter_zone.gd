extends Area2D
class_name EncounterZone



func _ready() -> void:
	Global.step_completed.connect(_on_step_completed)


func _on_step_completed(pos: Vector2) -> void:
	if check_position(pos):
		trigger()
	

func check_position(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collide_with_areas = true
	params.collision_mask = collision_layer
	var result = space_state.intersect_point(params, 1)
	for hit in result:
		print(hit.collider.name)
		if hit.collider == self:
			return true
	return false


func trigger() -> void:
	pass
