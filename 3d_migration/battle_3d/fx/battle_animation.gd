class_name BattleAnimation
extends Control

signal finished

@export var animation_player: AnimationPlayer


func play() -> void:
	animation_player.play("animation")
	await animation_player.animation_finished
	finished.emit()
