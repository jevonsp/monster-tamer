class_name SavedGame
extends Resource

@export var player_position: Vector2 = Vector2.ZERO
@export var player_party: Array[Monster] = []
@export var player_storage: Dictionary[int, Monster] = { }
@export var player_inventory: Dictionary[Item.Type, InventoryPage] = { }
@export var player_money: int = 0
@export var story_flags: Dictionary[Story.Flag, bool] = { }
@export var player_info: Dictionary = { }
@export var saved_data_array: Array[SavedData] = []
