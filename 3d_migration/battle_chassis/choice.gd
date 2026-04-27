class_name Choice
extends Resource

enum Type { MOVE, ITEM, SWITCH, FLEE }

var action: Variant
var type: Type = Type.MOVE
var actor: Monster = null
var targets: Array[Monster] = []
