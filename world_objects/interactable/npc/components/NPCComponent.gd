@abstract
class_name NPCComponent
extends Node

enum Result { CONTINUE, CONSUME, TERMINATE }

@export var is_active: bool = true


func trigger(_obj: Node) -> Result:
	return Result.CONTINUE
