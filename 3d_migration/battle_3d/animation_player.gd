class_name MoveAnimator
extends AnimationPlayer


func _play_animation(anim: StringName) -> void:
	assert(has_animation(anim))

	play(anim)
	await animation_finished


func _play_test() -> void:
	pass
