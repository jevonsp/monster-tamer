class_name DexTracker
extends Resource

@export var monster_list: Array[Monster] = []

var dex: Dictionary[Monster, bool] = { }


func _init() -> void:
	_create_dex()


func _create_dex() -> void:
	for monster in monster_list:
		dex[monster] = false


func _on_monster_caught(monster: Monster) -> bool:
	if dex[monster]:
		return false
	dex[monster] = true
	return true
