extends Node

var inventory: Dictionary[Item, int] = {}

func add(item: Item, amount: int = 1) -> void:
	if inventory.get(item):
		inventory[item] += amount
	else:
		inventory[item] = amount
	print("inventory now:")
	for i in inventory:
		print("%s: %s" % [inventory[i], i.name])


func send_player_inventory() -> void:
	Global.send_player_inventory.emit(inventory)
