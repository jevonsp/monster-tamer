extends EncounterZone

@export var encounter_table: Array[EncounterEntry] = []

func trigger() -> void:
	print("wild_zone trigger")
	choose_encounter()
	
	
func choose_encounter() -> void:
	var chances: Array[float]
	for e in encounter_table:
		chances.append(e.chance)
	chances.sort()
	var roll = randf()
	for e in encounter_table:
		if roll <= e.chance:
			var level = randi_range(e.level_low, e.level_high)
			Global.wild_battle_requested.emit(e.monster, level)
