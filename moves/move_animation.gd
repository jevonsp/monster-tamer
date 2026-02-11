extends Node2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_player_animation_finished)
	animation_player.play("move")

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	print_debug("Move Animation Finished")
	Global.move_animation_complete.emit()
	queue_free()
