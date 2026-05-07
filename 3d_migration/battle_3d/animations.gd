class_name Animations
extends Control

@onready var player_texture_rect: TextureRect = $PlayerTextureRect
@onready var enemy_texture_rect: TextureRect = $EnemyTextureRect


func play_animation(choice: Choice, chassis: BattleChassis) -> void:
	var packed_scene = (choice.action_or_list as Move).animation
	if not packed_scene:
		return
	var animation: MoveAnimation = packed_scene.instantiate()
	var animation_target: TextureRect
	var target = choice.targets[0]
	if chassis.is_player_actor(target):
		animation_target = player_texture_rect
	else:
		animation_target = enemy_texture_rect

	animation_target.add_child(animation)
	animation.play()
	await animation.finished
