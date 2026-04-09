class_name WildZone
extends EncounterZone

@export_range(0, 1.0) var overall_chance: float = .2
@export var encounter_table: Array[EncounterEntry] = []


func trigger() -> void:
	if roll_encounter():
		choose_encounter()
		return


func roll_encounter() -> bool:
	return randf() < overall_chance


func choose_encounter() -> void:
	Party.player_party_requested.emit()
	var total_chance := 0.0
	for e in encounter_table:
		total_chance += e.chance

	var roll = randf() * total_chance
	var cumulative_chance := 0.0

	for e in encounter_table:
		cumulative_chance += e.chance
		if roll <= cumulative_chance:
			var level = randi_range(e.level_low, e.level_high)
			Battle.wild_battle_requested.emit(e.monster, level)
			Battle.battle_started.emit()
			return


func _on_body_exited(body: Node2D) -> void:
	pass
