extends EncounterZone
class_name WildZone
@export_range(0, 1.0) var overall_chance: float = .2
@export var encounter_table: Array[EncounterEntry] = []

func trigger() -> void:
	if roll_encounter():
		choose_encounter()
		return


func roll_encounter() -> bool:
	return randf() < overall_chance
	
	
func choose_encounter() -> void:
	var total_chance := 0.0
	for e in encounter_table:
		total_chance += e.chance
	
	# We multiply by total chance. * 1 = 100%, * .5 = 50% etc
	# This makes the roll never go over.
	var roll = randf() * total_chance
	var cumulative_chance := 0.0
	
	for e in encounter_table:
		# Adding the chance each iteration ends up avoids errors
		cumulative_chance += e.chance
		if roll <= cumulative_chance:
			var level = randi_range(e.level_low, e.level_high)
			Global.player_party_requested.emit()
			Global.wild_battle_requested.emit(e.monster, level)
			return
