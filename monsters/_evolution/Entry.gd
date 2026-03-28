class_name Entry
extends Resource

enum Trigger { LEVEL_UP, ITEM_USE, TRADE }
enum Requirement { NONE, LEVEL, HOLD_ITEM, USE_ITEM }

@export var finish_monster: MonsterData = null
@export var trigger_type: Trigger = Trigger.LEVEL_UP
@export var requirement_type: Requirement = Requirement.LEVEL
@export_range(1, 100, 1) var required_level: int = 16
@export var required_item: Item = null


static func check_entry_level_up(monster: Monster, entry: Entry) -> bool:
	if entry.trigger_type != Trigger.LEVEL_UP:
		return false

	if entry.requirement_type == Requirement.LEVEL:
		return monster.level >= entry.required_level

	if entry.requirement_type == Requirement.HOLD_ITEM \
	and monster.held_item == entry.required_item:
		return monster.level >= entry.required_level

	return false


static func check_entry_item_use(item: Item, entry: Entry) -> bool:
	if entry.trigger_type != Trigger.ITEM_USE:
		return false

	if entry.requirement_type == Requirement.USE_ITEM and item == entry.required_item:
		return true

	return false


static func check_entry_trade(monster: Monster, entry: Entry) -> bool:
	if entry.trigger_type != Trigger.TRADE:
		return false

	if entry.requirement_type == Requirement.NONE:
		return true

	if entry.requirement_type == Requirement.HOLD_ITEM:
		assert(entry.required_item)
		return monster.held_item == entry.required_item

	return false
