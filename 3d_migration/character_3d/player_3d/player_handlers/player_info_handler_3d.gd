class_name PlayerInfo3D
extends Node

enum Gender { NONE, MALE, FEMALE, NB }
enum Model { A, B }

const _PLAYER_FIELDS: Array[StringName] = [
	&"player_name",
	&"player_gender",
	&"player_model",
	&"play_time",
	&"input_layout",
	&"respawn_point",
	&"nuzlocke_tracker",
	&"is_sidescrolling",
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
				pass
			Model.B:
				printerr("MODEL B NOT IMPLEMENTED")
@export var play_time: int = 0:
	set(value):
		play_time = value
		player_info["play_time"] = play_time
@export var input_layout: GameOptions.ControlScheme = GameOptions.ControlScheme.XBOX_SONY:
	set(value):
		input_layout = value
		player_info["input_layout"] = input_layout
		InputRemapper.apply(input_layout)
@export var respawn_point: Vector2 = Vector2.ZERO:
	set(value):
		respawn_point = value
		player_info["respawn_point"] = respawn_point
		if player:
			var p := Vector3(value.x, player.global_position.y, value.y)
			player.respawn_point = p
@export var nuzlocke_tracker: Dictionary = { }:
	set(value):
		nuzlocke_tracker = value
		player_info["nuzlocke_tracker"] = value
@export var is_sidescrolling: bool = false:
	set(value):
		is_sidescrolling = value
		player_info["is_sidescrolling"] = value
		if travel_handler:
			travel_handler.is_sidescrolling = value

var player: Player3D

@onready var travel_handler: TravelHandler3D = $"../TravelHandler"


func update_info() -> void:
	for prop in _PLAYER_FIELDS:
		if player_info.has(prop):
			set(prop, player_info[prop])


func _connect_signals() -> void:
	Global.time_changed.connect(_update_time_played)


func _update_time_played() -> void:
	play_time += 1
