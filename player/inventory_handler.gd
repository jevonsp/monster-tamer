class_name InventoryHandler
extends Node

@export var inventory: Dictionary[Item.Type, InventoryPage] = { }
@export var money: int = 0


func _ready() -> void:
	construct_inventory()


func add(item: Item, amount: int = 1) -> void:
	if inventory[item.item_type].page.has(item):
		inventory[item.item_type].page[item] += amount
	else:
		inventory[item.item_type].page[item] = amount
	send_player_inventory()


func remove(item: Item, amount: int = 1) -> void:
	if inventory[item.item_type].page.has(item):
		inventory[item.item_type].page[item] -= amount
		if inventory[item.item_type].page[item] == 0:
			inventory[item.item_type].page.erase(item)
	send_player_inventory()


func send_player_inventory() -> void:
	Inventory.send_player_inventory.emit(inventory)


func spend_money(amount: int) -> void:
	money -= amount
	Inventory.send_player_money.emit(money)


func construct_inventory() -> void:
	inventory[Item.Type.USE] = InventoryPage.new()
	inventory[Item.Type.BALL] = InventoryPage.new()
	inventory[Item.Type.HELD] = InventoryPage.new()
	inventory[Item.Type.KEY] = InventoryPage.new()


func on_use_item_on(item: Item, monster: Monster) -> void:
	await item.use(monster)
	if not item.is_multi_use:
		remove(item)
	Ui.item_finished_using.emit()


func on_give_item_to(item: Item, _monster: Monster) -> void:
	remove(item)


func has_item(item: Item) -> bool:
	for page: InventoryPage in inventory.values():
		for key: Item in page.page.keys():
			if key == item:
				return true
	return false


func _connect_signals() -> void:
	Inventory.use_item_on.connect(on_use_item_on)
	Inventory.give_item_to.connect(on_give_item_to)
	Inventory.item_used.connect(remove)
	Inventory.send_item_to_inventory.connect(add)
