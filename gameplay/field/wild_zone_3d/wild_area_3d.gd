class_name WildArea3D
extends CellObject

var wild_zone: WildZone3D


func _on_area_entered(area: Area3D) -> void:
	if area is not Player3D:
		return
	if not wild_zone:
		printerr("%s %s needs wild_zone" % [self.name, self])
		return
	await PlayerContext3D.walk_segmented_completed

	if wild_zone.encounter_table.is_empty():
		printerr("%s %s needs encounter table" % [wild_zone.name, wild_zone])
		return

	if wild_zone._roll_encounter():
		wild_zone._create_encounter()
