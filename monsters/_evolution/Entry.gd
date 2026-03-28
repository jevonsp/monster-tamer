class_name Entry
extends Resource

enum Trigger { LEVEL_UP, ITEM_USE, TRADE }
# LOCATION, KNOWS_MOVE, STAT_DISTRIBUTION
enum Requirement {
	NONE,
	LEVEL,
	HOLD_ITEM,
	USE_ITEM,
	GENDER,
	TIME_OF_DAY,
}

@export var finish_monster: MonsterData = null
@export var trigger_type: Trigger = Trigger.LEVEL_UP
@export var requirement_type: Requirement = Requirement.LEVEL
@export_range(1, 100, 1) var required_level: int = 16
@export var required_item: Item = null
@export var required_gender: MonsterData.Gender = MonsterData.Gender.GENDERLESS
@export var allowed_times_of_day: Array[TimeKeeper.TimeOfDay] = []


static func check_entry_level_up(monster: Monster, entry: Entry) -> bool:
	if entry.trigger_type != Trigger.LEVEL_UP:
		return false

	match entry.requirement_type:
		Requirement.LEVEL:
			return monster.level >= entry.required_level
		Requirement.HOLD_ITEM:
			if monster.held_item == entry.required_item:
				return monster.level >= entry.required_level
		Requirement.GENDER:
			if monster.gender == entry.required_gender:
				return monster.level >= entry.required_level
		Requirement.TIME_OF_DAY:
			var current_time = TimeKeeper.interpret_current_time()
			if current_time in entry.allowed_times_of_day:
				return monster.level >= entry.required_level

	return false


static func check_entry_item_use(monster: Monster, item: Item, entry: Entry) -> bool:
	if entry.trigger_type != Trigger.ITEM_USE:
		return false

	match entry.requirement_type:
		Requirement.LEVEL:
			return monster.level >= entry.required_level
		Requirement.USE_ITEM:
			if item == entry.required_item:
				return true

	return false


static func check_entry_trade(monster: Monster, entry: Entry) -> bool:
	if entry.trigger_type != Trigger.TRADE:
		return false

	match entry.requirement_type:
		Requirement.NONE:
			return true
		Requirement.HOLD_ITEM:
			if entry.required_item:
				return monster.held_item == entry.required_item

	return false
