class_name EncounterZone
extends Area2D

var wild_zone_parent: WildZone = null


func _ready() -> void:
	Global.step_completed.connect(_on_step_completed)


func check_position(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collide_with_areas = true
	params.collision_mask = collision_layer
	var result = space_state.intersect_point(params, 1)
	for hit in result:
		if hit.collider == self:
			return true
	return false


func trigger() -> void:
	if wild_zone_parent == null:
		return
	if roll_encounter():
		choose_encounter()


func roll_encounter() -> bool:
	return randf() < wild_zone_parent.overall_chance


func choose_encounter() -> void:
	Party.player_party_requested.emit()
	var total_chance := 0.0
	for e in wild_zone_parent.encounter_table:
		total_chance += e.chance

	var roll = randf() * total_chance
	var cumulative_chance := 0.0

	for e in wild_zone_parent.encounter_table:
		cumulative_chance += e.chance
		if roll <= cumulative_chance:
			var level = randi_range(e.level_low, e.level_high)
			Battle.wild_battle_requested.emit(e.monster, level)
			Battle.battle_started.emit()
			return


func _on_step_completed(pos: Vector2) -> void:
	if check_position(pos):
		trigger()
