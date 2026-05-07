class_name StatusData
extends Resource

enum StatusSlot { PRIMARY, SECONDARY, TERTIARY }

@export var name: String = ""
@export var on_apply: ActionList = null
@export var on_expire: ActionList = null
@export var on_turn_start: ActionList = null
@export var on_turn_end: ActionList = null
@export var on_potential_block: ActionList = null
@export var on_blocked_action: ActionList = null
