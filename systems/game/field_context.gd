class_name FieldContext
extends RefCounted

var session: GameSession
var grid_map: CombinedGridMap:
	get:
		return session.grid_map


func _init(p_session: GameSession) -> void:
	session = p_session
