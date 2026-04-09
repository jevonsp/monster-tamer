class_name WildZone
extends Node

@export_range(0, 1.0) var overall_chance: float = .2
@export var encounter_table: Array[EncounterEntry] = []

var grass_tiles: Array[GrassTile] = []


func _ready() -> void:
	_setup()


func _setup() -> void:
	for child in get_children():
		if child is GrassTile:
			grass_tiles.append(child)
			child.wild_zone_parent = self
