extends TeleporterObject

@onready var animation_player: AnimationPlayer = $Door/AnimationPlayer


func _ready() -> void:
	transition_animation_complete.connect(_reset_door)


func _play_animation() -> void:
	animation_player.play("open")
	await animation_player.animation_finished


func _reset_door() -> void:
	animation_player.play("RESET")
