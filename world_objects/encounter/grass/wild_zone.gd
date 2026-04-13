class_name WildZone
extends Node2D

@export_range(0, 1.0) var overall_chance: float = .2
@export var encounter_table: Array[EncounterEntry] = []


func _ready() -> void:
	_setup()


func _setup() -> void:
	for child in get_children():
		if child is EncounterZone:
			(child as EncounterZone).wild_zone_parent = self
