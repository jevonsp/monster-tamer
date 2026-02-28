extends Node

var inventory: Dictionary[Item, int] = {}

func _ready() -> void:
	Global.use_item_on.connect(_on_use_item_on)
	Global.give_item_to.connect(_on_give_item_to)


func add(item: Item, amount: int = 1) -> void:
	if inventory.get(item):
		inventory[item] += amount
	else:
		inventory[item] = amount
	print("inventory now:")
	for i in inventory:
		print("%s: %s" % [inventory[i], i.name])
	send_player_inventory()


func send_player_inventory() -> void:
	Global.send_player_inventory.emit(inventory)


func _on_use_item_on(item: Item, monster: Monster) -> void:
	await item.use(monster)
	
	
func _on_give_item_to(item: Item, monster: Monster) -> void:
	await monster.give(item)
	
	
