class_name WildZone3D
extends Node3D

@export_range(0.0, 1.0, 0.01) var encounter_rate: float = 0.15
@export var encounter_table: Array[EncounterEntry] = []


func _ready() -> void:
	_setup()


func _roll_encounter() -> bool:
	return randf() <= encounter_rate


func _create_encounter() -> void:
	Party.player_party_requested.emit()
	var total_chance := 0.0

	if encounter_table.is_empty():
		printerr("Encounter table on %s is empty" % self)
		return

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


func _setup() -> void:
	for child in get_children():
		if child is WildArea3D:
			child.wild_zone = self
