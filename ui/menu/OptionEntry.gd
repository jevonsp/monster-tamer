class_name OptionEntry
extends Resource

enum Type { TOGGLE, SERIES }

@export var type: Type = Type.TOGGLE
@export var entries: int = 2
@export var chosen_entry: int = 0
@export_subgroup("⬇️ Text ⬇️")
@export_multiline var entry_texts: Array[String] = []
