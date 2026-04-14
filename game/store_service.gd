extends Node


func try_buy(
		player_ref: Player,
		current_category: int,
		item: Item,
		amount: int,
		shop_inventory: Dictionary,
) -> Dictionary:
	if not player_ref:
		return { "ok": false, "message": "You don't have enough money for that." }
	if not _can_player_afford(player_ref, item):
		return { "ok": false, "message": "You don't have enough money for that." }
	if not _check_enough_stock(shop_inventory, current_category, item, amount):
		return { "ok": false, "message": "We don't have enough in stock, sorry!" }
	_pay_for_item(player_ref, item)
	_reduce_stock(shop_inventory, current_category, item, amount)
	return { "ok": true }


func try_sell(
		player_ref: Player,
		player_inventory: Dictionary,
		current_category: int,
		item: Item,
		amount: int,
) -> Dictionary:
	if not player_ref:
		return { "ok": false, "message": "" }
	if item.item_type == Item.Type.KEY:
		return { "ok": false, "message": "You can't sell me that!" }
	if not _check_enough_stock(player_inventory, current_category, item, amount):
		return { "ok": false, "message": "You don't have that many to sell." }
	player_ref.inventory_handler.remove(item, amount)
	credit_player_for_sale(player_ref, item, amount)
	return { "ok": true }


func credit_player_for_sale(player_ref: Player, item: Item, amount: int) -> void:
	var sell_value: int = maxi(1, int(item.price / 2.0))
	var total_value: int = sell_value * amount
	if player_ref.inventory_handler.has_method("add_money"):
		player_ref.inventory_handler.add_money(total_value)
		return
	var current_money: Variant = player_ref.inventory_handler.get("money")
	if typeof(current_money) == TYPE_INT:
		player_ref.inventory_handler.set("money", current_money + total_value)
		Inventory.send_player_money.emit(current_money + total_value)


func increase_npc_stock(npc_inventory: Dictionary, item: Item, amount: int) -> void:
	if not npc_inventory.has(item.item_type):
		npc_inventory[item.item_type] = InventoryPage.new()
	var page: InventoryPage = npc_inventory[item.item_type]
	if page.page.has(item):
		page.page[item] += amount
	else:
		page.page[item] = amount


func _can_player_afford(player_ref: Player, item: Item) -> bool:
	return player_ref.inventory_handler.money >= item.price


func _check_enough_stock(
		inventory: Dictionary,
		current_category: int,
		item: Item,
		amount: int,
) -> bool:
	if not inventory.has(current_category):
		return false
	var page: InventoryPage = inventory[current_category]
	if not page.page.has(item):
		return false
	return page.page[item] >= amount


func _pay_for_item(player_ref: Player, item: Item) -> void:
	player_ref.inventory_handler.adjust_money(-item.price)


func _reduce_stock(
		inventory: Dictionary,
		current_category: int,
		item: Item,
		amount: int,
) -> void:
	if not inventory.has(current_category):
		return
	var page: InventoryPage = inventory[current_category]
	if not page.page.has(item):
		return
	page.page[item] -= amount
	if page.page[item] <= 0:
		page.page.erase(item)
