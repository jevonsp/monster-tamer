class_name Weather
extends Resource

enum Type { NONE, SUN, RAIN, HAIL, SAND, WIND, MAGNET }
enum List { ENTRY, EXPIRY, PERSIST }

@export var turns_remaining: int = 5
@export var on_entry_action_list: ActionList = null
@export var on_expiry_action_list: ActionList = null
@export var on_persist_action_list: ActionList = null
@export var boosted_types: Array[TypeChart.Type] = []
@export var reduced_types: Array[TypeChart.Type] = []
