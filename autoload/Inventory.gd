extends Node

@warning_ignore_start("unused_signal")
signal send_player_inventory(inventory: Dictionary[Item.Type, InventoryPage])
signal send_player_money(amount: int)
signal send_item_to_inventory(item: Item)
signal player_inventory_requested
signal use_item_on(item: Item, monster: Monster)
signal give_item_to(item: Item, monster: Monster)
signal item_used(item: Item)
@warning_ignore_restore("unused_signal")
