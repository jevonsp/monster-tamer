extends Node

var inventory: Dictionary[Item, int] = {}

func _ready() -> void:
	Global.use_item_on.connect(_on_use_item_on)
	Global.give_item_to.connect(_on_give_item_to)
	Global.item_used.connect(remove)


func add(item: Item, amount: int = 1) -> void:
	if inventory.has(item):
		inventory[item] += amount
	else:
		inventory[item] = amount
	send_player_inventory()
	
	
func remove(item: Item, amount: int = 1) -> void:
	if inventory.has(item):
		inventory[item] -= amount
		if inventory[item] == 0:
			inventory.erase(item)
		send_player_inventory()


func send_player_inventory() -> void:
	Global.send_player_inventory.emit(inventory)


func _on_use_item_on(item: Item, monster: Monster) -> void:
	await item.use(monster)
	remove(item)
	
	
func _on_give_item_to(item: Item, monster: Monster) -> void:
	remove(item)
	
	
