class_name StatusData
extends Resource

enum StatusSlot { PRIMARY, SECONDARY, TERTIARY }
enum StackPolicy { REJECT, REFRESH, REPLACE }

@export var id: StringName = &""
@export var name: String = ""
@export var slot: StatusSlot = StatusSlot.TERTIARY
@export var default_duration: int = -1
@export var stack_policy: StackPolicy = StackPolicy.REJECT
## Passive multipliers applied for the entire lifetime of the status. Keyed by
## Monster.Stat (int), valued by float multiplier. Read by
## Monster.get_effective_stat. Empty for ticks-only statuses (e.g. poison).
@export var stat_multipliers: Dictionary = { }

@export_group("Hook Lists")
@export var on_apply: ActionList = null
@export var on_expire: ActionList = null
@export var on_turn_start: ActionList = null
@export var on_turn_end: ActionList = null
@export var on_potential_block: ActionList = null
@export var on_blocked_action: ActionList = null
