class_name BattlePresenter
extends RefCounted


func show_text(_lines: Array[String], _auto_complete: bool = false) -> void:
	pass


func play_move_animation(_choice: Choice) -> void:
	pass


func play_fx(_fx_id: StringName, _payload: Dictionary = { }) -> void:
	pass


func tween_hp(_target: Monster, _from_hp: int, _to_hp: int) -> void:
	pass
