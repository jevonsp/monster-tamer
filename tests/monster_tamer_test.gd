## Base for project tests: runs MonsterFactory.cleanup_round() so Monster refcount cycles do not leak.
extends GutTest


func after_each() -> void:
	MonsterFactory.cleanup_round()
