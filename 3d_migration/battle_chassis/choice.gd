class_name Choice
extends Resource

enum Type { MOVE, ITEM, SWITCH, FLEE }
enum UserSide { NONE, PLAYER, ENEMY }

var action: Variant
var type: Type = Type.MOVE
var actor: Monster = null
var side: UserSide = UserSide.NONE
var targets: Array[Monster] = []
