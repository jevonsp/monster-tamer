class_name BattlePresenter
extends RefCounted


func show_text(_ctx: ActionContext, _lines: Array[String], _auto_complete: bool = false) -> void:
	pass


func play_move_animation(_ctx: ActionContext, _choice: Choice) -> void:
	pass


func play_fx(_ctx: ActionContext, _fx_id: StringName, _payload: Dictionary = { }) -> void:
	pass


func play_fx_scene(_ctx: ActionContext, _scene: PackedScene, _target: Monster) -> void:
	pass


func tween_hp(_ctx: ActionContext, _target: Monster, _from_hp: int, _to_hp: int) -> void:
	pass
