class_name Info
extends Node

enum Gender { NONE, MALE, FEMALE, NB }
enum Model { A, B }

const PLAYER_SPRITE_SHEET = preload("uid://dmemkc7d8fav6")
const _PLAYER_FIELDS: Array[StringName] = [
	&"player_name",
	&"player_gender",
	&"player_model",
	&"play_time",
	&"input_layout",
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
		match player_model:
			Model.A:
				player.sprite_2d.texture = PLAYER_SPRITE_SHEET
			Model.B:
				printerr("MODEL B NOT IMPLEMENTED")
@export var play_time: int = 0:
	set(value):
		play_time = value
		player_info["play_time"] = play_time
@export var input_layout: InputRemapper.Layout = InputRemapper.Layout.SONY_XBOX:
	set(value):
		input_layout = value
		player_info["input_layout"] = input_layout
		match input_layout:
			InputRemapper.Layout.SONY_XBOX:
				InputRemapper.change_to_sony_xbox()
			InputRemapper.Layout.NINTENDO:
				InputRemapper.change_to_nintendo()

var player: Player


func update_info() -> void:
	for prop in _PLAYER_FIELDS:
		if player_info.has(prop):
			set(prop, player_info[prop])


func _connect_signals() -> void:
	Global.time_changed.connect(_update_time_played)


func _update_time_played() -> void:
	play_time += 1
