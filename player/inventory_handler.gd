extends Node

var inventory: Dictionary[Item.Type, InventoryPage] = {}

func _ready() -> void:
	_connect_signals()
	_construct_inventory()


func _connect_signals() -> void:
	Global.use_item_on.connect(_on_use_item_on)
	Global.give_item_to.connect(_on_give_item_to)
	Global.item_used.connect(remove)
	Global.send_item_to_inventory.connect(add)


func _construct_inventory() -> void:
	inventory[Item.Type.USE] = InventoryPage.new()
	inventory[Item.Type.HELD] = InventoryPage.new()
	inventory[Item.Type.KEY] = InventoryPage.new()


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
	Global.send_player_inventory.emit(inventory)


func _on_use_item_on(item: Item, monster: Monster) -> void:
	await item.use(monster)
	if not item.is_multi_use:
		remove(item)
	Global.item_finished_using.emit()
	
	
func _on_give_item_to(item: Item, _monster: Monster) -> void:
	remove(item)
	
