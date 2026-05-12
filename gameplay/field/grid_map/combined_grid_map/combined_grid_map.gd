class_name CombinedGridMap
extends Node3D

var gm_translator: GridMapTranslator


func _ready() -> void:
	var grid_maps: Array[GridMap]
	for child in get_children():
		if child is GridMap:
			grid_maps.append(child)
	gm_translator = GridMapTranslator.new(grid_maps)
