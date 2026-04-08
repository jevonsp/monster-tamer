class_name Info
extends Node

enum Gender { NONE, MALE, FEMALE, NB }
enum Model { A, B }

const _PLAYER_FIELDS: Array[StringName] = [
	&"player_name",
	&"player_gender",
	&"player_model",
]

@export var player_info: Dictionary = { }
@export var player_name: String = "":
	set(value):
		player_name = value
		player_info["player_name"] = player_name
@export var player_gender: Gender = Gender.NONE:
	set(value):
		player_gender = value
		player_info["player_gender"] = player_gender
@export var player_model: Model = Model.A:
	set(value):
		player_model = value
		player_info["player_model"] = player_model


func update_info() -> void:
	for prop in _PLAYER_FIELDS:
		if player_info.has(prop):
			set(prop, player_info[prop])
