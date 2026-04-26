class_name WildZone3D
extends Area3D

@export_range(0.0, 1.0, 0.01) var encounter_rate: float = 0.15
@export var encounter_table: Array[EncounterEntry] = []

var player_in_zone: bool = false


func _ready() -> void:
	PlayerContext3D.walk_segmented_completed.connect(_on_walk_segmented_completed)


func _on_walk_segmented_completed(_ground_cell: Vector3i) -> void:
	if player_in_zone:
		if _roll_encounter():
			_create_encounter()


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


func _on_area_entered(area: Area3D) -> void:
	if area is Player3D:
		player_in_zone = true
		print('entered')


func _on_area_exited(area: Area3D) -> void:
	if area is Player3D:
		player_in_zone = false
		print('exited')
