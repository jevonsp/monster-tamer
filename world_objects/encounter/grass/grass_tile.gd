class_name GrassTile
extends EncounterZone

var wild_zone_parent: WildZone = null


func trigger() -> void:
	if roll_encounter():
		choose_encounter()
		return


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


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.bottom_sprite_2d.visible = false
		body.top_sprite_2d.z_index = 1


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body.bottom_sprite_2d.visible = true
		body.top_sprite_2d.z_index = 0
