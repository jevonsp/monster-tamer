class_name ActionContext
extends RefCounted

var chassis: BattleChassis
var choice: Choice
var presenter: BattlePresenter
var data: Dictionary = { }


func _init(
		p_chassis: BattleChassis,
		p_choice: Choice,
		p_presenter: BattlePresenter,
) -> void:
	chassis = p_chassis
	choice = p_choice
	presenter = p_presenter


func fork(deep_copy_data: bool = true) -> ActionContext:
	var copy := ActionContext.new(chassis, choice, presenter)
	copy.data = data.duplicate(deep_copy_data)
	return copy
