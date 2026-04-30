class_name Choice
extends Resource

enum Type { MOVE, ITEM, SWITCH, FLEE }
enum Target { NONE, ENEMY, USER, ALLIES, ENEMIES, OTHERS, ALL }

var action_or_list: Variant
var type: Type = Type.MOVE
var actor: Monster = null
var targets: Array[Monster] = []


func _to_string() -> String:
	return "Choice: type: {type} actor: {actor} target: {targets}".format(
		{
			"type": Type.keys()[type],
			"actor": actor.name,
			"target": targets[0].name,
		},
	)
