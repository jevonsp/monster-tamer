class_name ActionBlockerObject
extends BlockerObject

enum Requirement { NONE, ITEM, TYPE, MOVE }

@export var requirement_type: Requirement = Requirement.NONE
