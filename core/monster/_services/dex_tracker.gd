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


func hydrate_from_save(raw: Variant) -> void:
	if raw is DexTracker:
		var source = raw
		monster_list = source.monster_list.duplicate()
		dex = source.dex.duplicate()
		if dex.is_empty() and not monster_list.is_empty():
			_create_dex()
		return
	_create_dex()
