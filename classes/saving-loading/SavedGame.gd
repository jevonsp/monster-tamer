extends Resource
class_name SavedGame

@export var player_position: Vector2 = Vector2.ZERO
@export var player_party: Array[Monster] = []
@export var player_storage: Dictionary[int, Monster] = {}

@export var saved_data_array: Array[SavedData] = []
